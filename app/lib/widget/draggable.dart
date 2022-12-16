import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:np_codegen/np_codegen.dart';

part 'draggable.g.dart';

@npLog
class Draggable<T extends Object> extends StatelessWidget {
  const Draggable({
    Key? key,
    required this.data,
    required this.child,
    this.feedback,
    this.onDropBefore,
    this.onDropAfter,
    this.onDragStarted,
    this.onDragEndedAny,
    this.feedbackSize,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    buildIndicator(alignment, isActive) {
      return Stack(
        children: [
          Container(),
          Visibility(
            visible: isActive,
            child: Align(
              alignment: alignment,
              child: Container(
                constraints: const BoxConstraints.tightFor(width: 2),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: LongPressDraggable<T>(
            data: data,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: onDragStarted,
            onDragEnd: (_) => onDragEndedAny?.call(),
            onDragCompleted: onDragEndedAny,
            onDraggableCanceled: (v, o) => onDragEndedAny?.call(),
            feedback: FractionalTranslation(
              translation: const Offset(-.5, -.5),
              child: SizedBox(
                width: feedbackSize?.width ?? 128,
                height: feedbackSize?.height ?? 128,
                child: Opacity(
                  opacity: .5,
                  child: feedback ?? child,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: .25,
              child: child,
            ),
            child: child,
          ),
        ),
        if (onDropBefore != null || onDropAfter != null)
          Positioned.fill(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (onDropBefore != null)
                  Expanded(
                    child: DragTarget<T>(
                      builder: (context, candidateItems, rejectedItems) {
                        return buildIndicator(AlignmentDirectional.centerStart,
                            candidateItems.isNotEmpty);
                      },
                      onAccept: (item) {
                        _log.fine("[build] Dropping $item before $data");
                        onDropBefore!(item);
                      },
                    ),
                  ),
                if (onDropAfter != null)
                  Expanded(
                    child: DragTarget<T>(
                      builder: (context, candidateItems, rejectedItems) {
                        return buildIndicator(AlignmentDirectional.centerEnd,
                            candidateItems.isNotEmpty);
                      },
                      onAccept: (item) {
                        _log.fine("[build] Dropping $item after $data");
                        onDropAfter!(item);
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  final T data;
  final Widget child;
  final Widget? feedback;

  /// Called when some item dropped before this item
  final DragTargetAccept<T>? onDropBefore;

  /// Called when some item dropped after this item
  final DragTargetAccept<T>? onDropAfter;

  final VoidCallback? onDragStarted;

  /// Called when either one of onDragEnd, onDragCompleted or
  /// onDraggableCanceled is called.
  ///
  /// The callback might be called multiple times per each drag event
  final VoidCallback? onDragEndedAny;

  /// Size of the feedback widget that appears under the pointer.
  ///
  /// Right now a translucent version of [child] is being shown
  final Size? feedbackSize;
}
