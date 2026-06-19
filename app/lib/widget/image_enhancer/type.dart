part of 'image_enhancer.dart';

enum _Method {
  retouch,
  superResolution,
  motionDeblur,
  derain;

  ImageEnhancerTaskType toImageEnhancerTask() {
    return switch (this) {
      retouch => ImageEnhancerTaskType.retouch,
      superResolution => ImageEnhancerTaskType.superResolution,
      motionDeblur => ImageEnhancerTaskType.motionDeblur,
      derain => ImageEnhancerTaskType.derain,
    };
  }

  String get title {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchTitle,
      superResolution => L10n.global().enhanceSuperResolution4xTitle,
      // TODO string
      motionDeblur => "Motion deblur",
      // TODO string
      derain => "Derain",
    };
  }

  String get description {
    return switch (this) {
      retouch => L10n.global().enhanceRetouchDescription,
      superResolution => L10n.global().enhanceSuperResolution4xDescription,
      // TODO string
      motionDeblur => "Remove camera shake",
      // TODO string
      derain => "Remove rain",
    };
  }

  Uri get helpUri {
    return switch (this) {
      retouch => Uri.parse(help_util.enhanceRetouchUrl),
      superResolution => Uri.parse(help_util.enhanceSuperResolutionUrl),
      motionDeblur => Uri.parse(help_util.enhanceMotionDeblurUrl),
      derain => Uri.parse(help_util.enhanceDerainUrl),
    };
  }
}
