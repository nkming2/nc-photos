part of 'image_enhancer.dart';

enum _Method {
  retouch,
  lowLight,
  superResolution,
  // motionDeblur,
  derain;

  ImageEnhancerTaskType toImageEnhancerTask() {
    return switch (this) {
      retouch => ImageEnhancerTaskType.retouch,
      lowLight => ImageEnhancerTaskType.lowLight,
      superResolution => ImageEnhancerTaskType.superResolution,
      // motionDeblur => ImageEnhancerTaskType.motionDeblur,
      derain => ImageEnhancerTaskType.derain,
    };
  }

  String get title {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchTitle,
      lowLight => L10n.global().enhanceLowLightTitle,
      superResolution => L10n.global().enhanceSuperResolution4xTitle,
      // motionDeblur => L10n.global().enhanceMotionDeblurTitle,
      derain => L10n.global().enhanceDerainTitle,
    };
  }

  String get description {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchDescription,
      lowLight => L10n.global().enhanceLowLightDescription,
      superResolution => L10n.global().enhanceSuperResolution4xDescription,
      // motionDeblur => L10n.global().enhanceMotionDeblurDescription,
      derain => L10n.global().enhanceDerainDescription,
    };
  }

  Uri get helpUri {
    return switch (this) {
      retouch => Uri.parse(help_util.enhanceRetouchUrl),
      lowLight => Uri.parse(help_util.enhanceLowLightUrl),
      superResolution => Uri.parse(help_util.enhanceSuperResolutionUrl),
      // motionDeblur => Uri.parse(help_util.enhanceMotionDeblurUrl),
      derain => Uri.parse(help_util.enhanceDerainUrl),
    };
  }
}
