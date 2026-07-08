part of 'image_enhancer.dart';

enum _Method {
  retouch,
  lowLight,
  superResolution,
  // motionDeblur,
  derain,
  portraitBlur,
  colorPop;

  ImageEnhancerTaskType toImageEnhancerTask() {
    return switch (this) {
      retouch => ImageEnhancerTaskType.retouch,
      lowLight => ImageEnhancerTaskType.lowLight,
      superResolution => ImageEnhancerTaskType.superResolution,
      // motionDeblur => ImageEnhancerTaskType.motionDeblur,
      derain => ImageEnhancerTaskType.derain,
      portraitBlur => ImageEnhancerTaskType.portraitBlur,
      colorPop => ImageEnhancerTaskType.colorPop,
    };
  }

  String get title {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchTitle,
      lowLight => L10n.global().enhanceLowLightTitle,
      superResolution => L10n.global().enhanceSuperResolution4xTitle,
      // motionDeblur => L10n.global().enhanceMotionDeblurTitle,
      derain => L10n.global().enhanceDerainTitle,
      portraitBlur => L10n.global().enhancePortraitBlurTitle,
      colorPop => L10n.global().enhanceColorPopTitle,
    };
  }

  String get description {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchDescription,
      lowLight => L10n.global().enhanceLowLightDescription,
      superResolution => L10n.global().enhanceSuperResolution4xDescription,
      // motionDeblur => L10n.global().enhanceMotionDeblurDescription,
      derain => L10n.global().enhanceDerainDescription,
      portraitBlur => L10n.global().enhancePortraitBlurDescription,
      colorPop => L10n.global().enhanceColorPopDescription,
    };
  }

  Uri get helpUri {
    return switch (this) {
      retouch => Uri.parse(help_util.enhanceRetouchUrl),
      lowLight => Uri.parse(help_util.enhanceLowLightUrl),
      superResolution => Uri.parse(help_util.enhanceSuperResolutionUrl),
      // motionDeblur => Uri.parse(help_util.enhanceMotionDeblurUrl),
      derain => Uri.parse(help_util.enhanceDerainUrl),
      portraitBlur => Uri.parse(help_util.enhancePortraitBlurUrl),
      colorPop => Uri.parse(help_util.enhanceColorPopUrl),
    };
  }

  bool get isRequireImageSegment => switch (this) {
    portraitBlur || colorPop => true,
    _ => false,
  };
}
