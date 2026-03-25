# Generated file. Do not edit.

def flutter_root
  generated_xconfig_path = File.join(File.dirname(__FILE__), 'Generated.xcconfig')
  unless File.exist?(generated_xconfig_path)
    # In CI, Generated.xcconfig might not be in the repo, but flutter pub get will create it.
    # If we are here, something is wrong with the build order.
    return nil
  end

  File.foreach(generated_xconfig_path) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
    return matches[1].strip if matches
  end
  nil
end

root_path = flutter_root
if root_path
  require File.expand_path(File.join(root_path, 'packages', 'flutter_tools', 'bin', 'podhelper'), __FILE__)
end
