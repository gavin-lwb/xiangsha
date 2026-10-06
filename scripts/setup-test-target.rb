#!/usr/bin/env ruby
# frozen_string_literal: true

# ==============================================================================
# setup-test-target.rb
#
# P0-3 T1：自动把 xiangshaTests Unit Test Bundle 接入 Xcode 工程
# 关联文档：~/project/xiangsha/Tests/UnitTests/README.md
#
# 设计要点：
#   - 三阶段：preflight → mutate → verify（每阶段独立 [OK]/[WARN]/[FAIL] 输出）
#   - Idempotent：第二次跑检测到 xiangshaTests 已存在则跳过 mutate，只跑 verify
#   - 自动回滚：任何阶段失败 → 从 pbxproj 备份恢复 → 退出码非 0
#   - xcodeproj gem：优先 GEM_HOME 环境变量；fallback 自动探测 cocoapods 内置 gem
#   - 绝不把测试文件加进 xiangsha app target（避免 @testable import 自引用）
# ==============================================================================

require 'fileutils'
require 'open3'
require 'time'

# -----------------------------------------------------------------------------
# 配置常量
# -----------------------------------------------------------------------------

PROJECT_ROOT  = File.expand_path('~/project/xiangsha')
PROJECT_PATH  = File.join(PROJECT_ROOT, 'xiangsha.xcodeproj')
PBXPROJ_PATH  = File.join(PROJECT_PATH, 'project.pbxproj')
TESTS_DIR     = File.join(PROJECT_ROOT, 'Tests', 'UnitTests')

APP_TARGET     = 'xiangsha'
TESTS_TARGET   = 'xiangshaTests'
SCHEME         = 'xiangsha'
BUNDLE_ID     = 'Claude.lwb.xiangshaTests'
DEPLOY_TARGET = '17.0'
SWIFT_VERSION = '5.0'
DEVELOPMENT_TEAM = '645896882J'  # 与主 app 对齐
DESTINATION    = 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# 5 个测试 .swift（必须加入 xiangshaTests target）
TEST_FILES = %w[
  DrawEngineTests.swift
  EatViewModelTests.swift
  PlayViewModelTests.swift
  DoViewModelTests.swift
  PhotoViewModelTests.swift
].freeze

SUPPORT_DIR = 'Support'

# Tests 目录相对工程根的路径（Xcode group 使用）
TESTS_REL = 'Tests/UnitTests'

# -----------------------------------------------------------------------------
# 输出 helper
# -----------------------------------------------------------------------------

def ok(msg)
  puts "[OK]   #{msg}"
end

def info(msg)
  puts "[INFO] #{msg}"
end

def warn(msg)
  puts "[WARN] #{msg}"
end

def fail(msg)
  puts "[FAIL] #{msg}"
  exit 1
end

def section(title)
  puts ''
  puts "=== #{title} ==="
end

# -----------------------------------------------------------------------------
# xcodeproj gem 加载（兼容系统 Ruby 2.6 + CocoaPods 自带 xcodeproj 1.27）
# -----------------------------------------------------------------------------

def load_xcodeproj
  # 1) 优先尝试 GEM_HOME 已经配置好的（用户直接 ruby 调脚本）
  begin
    require 'xcodeproj'
    return
  rescue LoadError
    # 继续 fallback
  end

  # 2) Fallback：探测 CocoaPods 内置 xcodeproj
  cocoapods_gem_home = '/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec'
  if File.directory?(cocoapods_gem_home)
    ENV['GEM_HOME'] = cocoapods_gem_home
    Gem.clear_paths
    begin
      require 'xcodeproj'
      return
    rescue LoadError => e
      raise LoadError,
            "xcodeproj 加载失败：#{e.message}\n" \
            "请检查 GEM_HOME=#{cocoapods_gem_home} 是否存在 xcodeproj gem"
    end
  end

  raise LoadError, 'xcodeproj gem 不可用，请安装：gem install --user-install xcodeproj'
end

# -----------------------------------------------------------------------------
# 阶段 1：preflight（只读检查，不修改任何文件）
# -----------------------------------------------------------------------------

def preflight
  section '[1/3] PREFLIGHT'

  # 1.1 xcodeproj gem
  load_xcodeproj
  ok("xcodeproj gem loaded (#{Xcodeproj::VERSION})")

  # 1.2 主 app 工程存在
  unless File.directory?(PROJECT_PATH)
    fail("主 app 工程目录不存在: #{PROJECT_PATH}")
  end
  unless File.exist?(PBXPROJ_PATH)
    fail("project.pbxproj 不存在: #{PBXPROJ_PATH}")
  end
  ok("主 app 工程存在: #{PROJECT_PATH}")

  # 1.3 5 个测试文件齐全
  TEST_FILES.each do |fname|
    fpath = File.join(TESTS_DIR, fname)
    unless File.exist?(fpath)
      fail("测试文件缺失: #{fpath}")
    end
  end
  ok("5 个测试 .swift 文件齐全")

  # 1.4 Support/ 目录
  support_dir = File.join(TESTS_DIR, SUPPORT_DIR)
  unless File.directory?(support_dir)
    fail("Support/ 目录不存在: #{support_dir}")
  end
  support_swifts = Dir.glob(File.join(support_dir, '*.swift'))
  if support_swifts.empty?
    fail("Support/ 下无 .swift 文件")
  end
  ok("Support/ 存在（#{support_swifts.size} 个 .swift: #{support_swifts.map { |s| File.basename(s) }.join(', ')}）")

  # 1.5 模拟器 iPhone 17 可用
  sim_out, _ = Open3.capture2('xcrun', 'simctl', 'list', 'devices', 'available')
  unless sim_out =~ /iPhone 17/
    warn("未检测到 iPhone 17 模拟器，请确认 xcodebuild -showsdks 可用 iOS 18 SDK")
  else
    ok("iPhone 17 模拟器可用")
  end

  info("preflight 全部通过")
end

# -----------------------------------------------------------------------------
# 阶段 2：mutate（修改 pbxproj；idempotent：已存在则跳过）
# -----------------------------------------------------------------------------

def mutate
  section '[2/3] MUTATE'

  # 2.1 备份
  backup_path = "#{PBXPROJ_PATH}.bak-#{Time.now.to_i}"
  FileUtils.cp(PBXPROJ_PATH, backup_path)
  ok("已备份 project.pbxproj → #{File.basename(backup_path)}")

  begin
    # 2.2 打开工程
    project = Xcodeproj::Project.open(PROJECT_PATH)

    # 2.3 定位主 app target
    app_target = project.targets.find { |t| t.name == APP_TARGET }
    unless app_target
      rollback(backup_path)
      fail("未找到主 app target: #{APP_TARGET}")
    end
    ok("找到主 app target: #{APP_TARGET} (#{app_target.uuid})")

    # 2.4 idempotent 检查：tests target 已存在则跳过 mutate
    tests_target = project.targets.find { |t| t.name == TESTS_TARGET }
    if tests_target
      ok("tests target 已存在（idempotent 跳过 mutate）: #{TESTS_TARGET} (#{tests_target.uuid})")
      info("提示：再次运行只会跑 verify，不会重复创建")
      return backup_path
    end

    # 2.5 创建 xiangshaTests target
    tests_target = project.new_target(
      :unit_test_bundle,
      TESTS_TARGET,
      :ios,
      DEPLOY_TARGET,
      project.products_group,
      :swift
    )
    ok("创建 tests target: #{TESTS_TARGET} (#{tests_target.uuid})")

    # 2.6 配置 build settings（Debug + Release 都设）
    tests_target.build_configurations.each do |config|
      bs = config.build_settings
      bs['PRODUCT_BUNDLE_IDENTIFIER']    = BUNDLE_ID
      bs['PRODUCT_NAME']                 = '$(TARGET_NAME)'
      bs['IPHONEOS_DEPLOYMENT_TARGET']   = DEPLOY_TARGET
      bs['TEST_HOST']                    = '$(BUILT_PRODUCTS_DIR)/xiangsha.app/xiangsha'
      bs['BUNDLE_LOADER']                = '$(TEST_HOST)'
      bs['SWIFT_VERSION']                = SWIFT_VERSION
      bs['LD_RUNPATH_SEARCH_PATHS']      = [
        '$(inherited)',
        '@executable_path/Frameworks',
        '@loader_path/Frameworks'
      ]
      bs['GENERATE_INFOPLIST_FILE']      = 'YES'
      bs['CODE_SIGN_STYLE']              = 'Automatic'
      bs['DEVELOPMENT_TEAM']             = DEVELOPMENT_TEAM
      # 模拟器测试不签名（避免证书问题）
      bs['CODE_SIGNING_ALLOWED']         = 'NO'
      # 与主 app 对齐
      bs['TARGETED_DEVICE_FAMILY']       = '1,2'
    end
    ok("配置 build settings: Bundle ID / Test Host / Bundle Loader / iOS #{DEPLOY_TARGET}")

    # 2.7 加依赖：tests target → 主 app target
    tests_target.add_dependency(app_target)
    ok("依赖关系: #{TESTS_TARGET} → #{APP_TARGET}")

    # 2.8 加入测试文件：用 project.main_group.new_file(...) 让 Xcodeproj 自动
    #     沿着路径递归创建中间 group（每个 group 的 path 都正确设了），
    #     最终 PBXFileReference.path 是完整相对路径 "Tests/UnitTests/X.swift"，
    #     Xcode 解析后定位正确。
    #     （之前 group.path=nil → source_tree="<group>" 解析失败会导致 xcodebuild
    #     报 "Build input files cannot be found"。）
    added_files = []
    TEST_FILES.each do |fname|
      file_ref = project.main_group.new_file("#{TESTS_REL}/#{fname}")
      unless tests_target.source_build_phase.files_references.include?(file_ref)
        tests_target.source_build_phase.add_file_reference(file_ref)
      end
      added_files << fname
    end
    ok("加入测试文件: #{added_files.join(', ')}")

    # 2.9 把 Support/ 下的每个 .swift 作为 group file 加入 tests target
    #    ❌ 不能用 folder reference（Xcode 不会编译里面的 Swift）
    #    ✅ 正确做法：Support/ 作为 group，逐文件 add_file_reference
    support_dir = File.join(TESTS_DIR, SUPPORT_DIR)
    support_swift_files = Dir.glob(File.join(support_dir, '*.swift'))
    if support_swift_files.empty?
      warn("Support/ 下无 .swift 文件，跳过")
    else
      support_swift_files.each do |sfpath|
        fname = File.basename(sfpath)
        file_ref = project.main_group.new_file("#{TESTS_REL}/#{SUPPORT_DIR}/#{fname}")
        unless tests_target.source_build_phase.files_references.include?(file_ref)
          tests_target.source_build_phase.add_file_reference(file_ref)
        end
      end
      ok("加入 Support/ 下的 Swift 文件: #{support_swift_files.map { |s| File.basename(s) }.join(', ')}")
    end

    # 2.11 保存
    project.save
    ok("project.pbxproj 已保存")

    info("mutate 完成：target 创建 + 文件加入 + 依赖建立")
    backup_path
  rescue StandardError => e
    warn("mutate 异常: #{e.class}: #{e.message}")
    puts e.backtrace.first(8).join("\n")
    rollback(backup_path)
    fail("mutate 阶段失败，已回滚到原始 pbxproj")
  end
end

# -----------------------------------------------------------------------------
# 阶段 3：verify（跑 build-for-testing 验证整链路）
# -----------------------------------------------------------------------------

def verify(backup_path)
  section '[3/3] VERIFY'

  cmd = [
    'xcodebuild', 'build-for-testing',
    '-project', PROJECT_PATH,
    '-scheme', SCHEME,
    '-destination', DESTINATION
  ]
  info("运行: #{cmd.join(' ')}")

  begin
    out, status = Open3.capture2e(*cmd)
  rescue StandardError => e
    warn("xcodebuild 调用失败: #{e.message}")
    rollback(backup_path)
    fail("verify 阶段异常，已回滚")
  end

  if status.success? && out.include?('TEST BUILD SUCCEEDED')
    ok("** TEST BUILD SUCCEEDED **")
    # 成功才删备份
    if File.exist?(backup_path)
      File.delete(backup_path)
      ok("清理备份文件")
    end
    return true
  end

  # 失败路径
  warn("build-for-testing 未通过")
  puts '    --- last 30 lines of output ---'
  puts out.lines.last(30).join
  rollback(backup_path)
  fail("verify 阶段失败，已回滚")
end

# -----------------------------------------------------------------------------
# 回滚
# -----------------------------------------------------------------------------

def rollback(backup_path)
  if backup_path && File.exist?(backup_path)
    FileUtils.cp(backup_path, PBXPROJ_PATH)
    warn("已从备份恢复: #{File.basename(backup_path)}")
  else
    warn("备份不存在，无法回滚")
  end
end

# -----------------------------------------------------------------------------
# 主流程
# -----------------------------------------------------------------------------

begin
  info("scripts/setup-test-target.rb 启动")
  info("工程: #{PROJECT_PATH}")
  preflight
  backup_path = mutate
  verify(backup_path)
  puts ''
  puts '=== ALL DONE ✅ ==='
  puts 'xiangshaTests Unit Test Bundle 已接入'
  puts '接下来可以跑: xcodebuild test -scheme xiangsha -destination \'platform=iOS Simulator,name=iPhone 17,OS=latest\''
rescue SystemExit
  raise
rescue StandardError => e
  warn("未捕获异常: #{e.class}: #{e.message}")
  puts e.backtrace.first(5).join("\n")
  exit 1
end