Pod::Spec.new do |s|
  s.name     = 'JPSVolumeButtonHandler@SpoonConsulting'
  s.version  = '1.0.0'
  s.platform = :ios, "7.0"
  s.license  = 'MIT'
  s.summary  = 'JPSVolumeButtonHandler provides an easy block interface to hardware volume buttons on iOS devices. Perfect for camera apps!'
  s.homepage = 'https://github.com/spoonconsulting/JPSVolumeButtonHandler'
  s.author   = { 'SharinPix Admin' => 'admin@sharinpix.com', 'Zafir Sk Heerah' => 'zafir.heerah@spoonconsulting.com', 'JP Simard' => 'jp@jpsim.com' }
  s.source   = { :git => 'https://github.com/spoonconsulting/JPSVolumeButtonHandler.git', :tag => s.version.to_s }

  s.description = 'JPSVolumeButtonHandler provides an easy block interface to hardware volume buttons on iOS devices. Perfect for camera apps! Features:\n* Run blocks whenever a hardware volume button is pressed\n* Volume button presses don\'t affect system audio\n* Hide the HUD typically displayed on volume button presses\n* Works even when the system audio level is at its maximum or minimum, even when muted'

  s.source_files = 'JPSVolumeButtonHandler/*.{h,m}'
  s.framework    = 'MediaPlayer', 'AVFoundation'
  s.requires_arc = true
end
