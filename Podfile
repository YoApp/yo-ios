
platform :ios, '8.0'
inhibit_all_warnings!

project 'Yo'

#link_with 'YoInHouse', 'YoAppStore'

target :'YoInHouse' do
    pod 'Optimizely-iOS-SDK'
    pod 'JBWhatsAppActivity'
    pod 'Appirater'
    pod 'FXBlurView'
    pod 'RHAddressBook'
    pod 'Smooch'
    pod 'NJKWebViewProgress'
    pod 'CHCSVParser'
    pod 'SwipeView'
    pod 'TUSafariActivity', '~> 1.0'
    pod 'UIActionSheet+Blocks'
    pod 'MBProgressHUD', '~> 0.8'
    pod 'THLabel', '~> 1.4.3'
    # begin pods included in all targets
    pod 'SSKeychain'
    pod 'AWSS3'
    pod 'AFNetworking', '~> 2.0'
    pod 'OpenUDID'
    pod 'CocoaLumberjack', '~>1.9'
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Batch', '~> 1.4'
end

target :'YoAppStore' do
    pod 'Optimizely-iOS-SDK'
    pod 'JBWhatsAppActivity'
    pod 'Appirater'
    pod 'FXBlurView'
    pod 'RHAddressBook'
    pod 'Smooch'
    pod 'NJKWebViewProgress'
    pod 'CHCSVParser'
    pod 'SwipeView'
    pod 'TUSafariActivity', '~> 1.0'
    pod 'UIActionSheet+Blocks'
    pod 'MBProgressHUD', '~> 0.8'
    pod 'THLabel', '~> 1.4.3'
    # begin pods included in all targets
    pod 'SSKeychain'
    pod 'AWSS3'
    pod 'AFNetworking', '~> 2.0'
    pod 'OpenUDID'
    pod 'CocoaLumberjack', '~>1.9'
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Batch', '~> 1.4'
    pod 'Branch'
end

target :'YoAppExtension' do
    # begin pods included in all targets
    pod 'SSKeychain'
    pod 'AWSS3'
    pod 'AFNetworking', '~> 2.0'
    pod 'OpenUDID'
    pod 'CocoaLumberjack', '~>1.9'
end

target :'YoAppExtensionInHouse' do
    # begin pods included in all targets
    pod 'SSKeychain'
    pod 'AWSS3'
    pod 'AFNetworking', '~> 2.0'
    pod 'OpenUDID'
    pod 'CocoaLumberjack', '~>1.9'
end


target :'Yo WatchKit Extension' do
    # begin pods included in all targets
    pod 'SSKeychain'
    pod 'AFNetworking', '~> 2.0'
    pod 'OpenUDID'
    pod 'CocoaLumberjack', '~>1.9'
end

def remove_copy_frameworks_phase_for_extensions(installer)
    installer.aggregate_targets.each do |aggregate|
        case aggregate.name
            when 'Pods-share_extension', 'Pods-today_widget'
            if aggregate.user_targets.count == 1
                puts 'Removing "Embed Pods Frameworks" build phase from extension target'
                pod_target = aggregate.user_targets.first
                phase = pod_target.shell_script_build_phases.select { |p| p.name == 'Embed Pods Frameworks' }.first
                phase.remove_from_project
                pod_target.project.save
            end
        end
    end
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        if target.name == "Pods-YoAppExtension-AFNetworking" || target.name == "Pods-YoAppExtensionInHouse-AFNetworking" || target.name == "Pods-Yo\ WatchKit\ Extension-AFNetworking"
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'AF_APP_EXTENSIONS=1']
            end
        end
    end
    remove_copy_frameworks_phase_for_extensions(installer_representation)
end




#post_install do |installer|
#    installer.project.targets.each do |target|
#        puts "#{target.name}"
#    end
#end
