// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// DriftTableSortGenerator
// **************************************************************************

enum RecognizeFaceItemSort {
  rowIdAsc,
  rowIdDesc,
  parentAsc,
  parentDesc,
  relativePathAsc,
  relativePathDesc,
  fileIdAsc,
  fileIdDesc,
  contentLengthAsc,
  contentLengthDesc,
  contentTypeAsc,
  contentTypeDesc,
  etagAsc,
  etagDesc,
  lastModifiedAsc,
  lastModifiedDesc,
  hasPreviewAsc,
  hasPreviewDesc,
  realPathAsc,
  realPathDesc,
  isFavoriteAsc,
  isFavoriteDesc,
  fileMetadataWidthAsc,
  fileMetadataWidthDesc,
  fileMetadataHeightAsc,
  fileMetadataHeightDesc,
  faceDetectionsAsc,
  faceDetectionsDesc,
}

extension RecognizeFaceItemSortIterableExtension
    on Iterable<RecognizeFaceItemSort> {
  Iterable<OrderingTerm> toOrderingItem(SqliteDb db) {
    return map((s) {
      switch (s) {
        case RecognizeFaceItemSort.rowIdAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.rowId);
        case RecognizeFaceItemSort.rowIdDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.rowId);
        case RecognizeFaceItemSort.parentAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.parent);
        case RecognizeFaceItemSort.parentDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.parent);
        case RecognizeFaceItemSort.relativePathAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.relativePath);
        case RecognizeFaceItemSort.relativePathDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.relativePath);
        case RecognizeFaceItemSort.fileIdAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.fileId);
        case RecognizeFaceItemSort.fileIdDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.fileId);
        case RecognizeFaceItemSort.contentLengthAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.contentLength);
        case RecognizeFaceItemSort.contentLengthDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.contentLength);
        case RecognizeFaceItemSort.contentTypeAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.contentType);
        case RecognizeFaceItemSort.contentTypeDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.contentType);
        case RecognizeFaceItemSort.etagAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.etag);
        case RecognizeFaceItemSort.etagDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.etag);
        case RecognizeFaceItemSort.lastModifiedAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.lastModified);
        case RecognizeFaceItemSort.lastModifiedDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.lastModified);
        case RecognizeFaceItemSort.hasPreviewAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.hasPreview);
        case RecognizeFaceItemSort.hasPreviewDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.hasPreview);
        case RecognizeFaceItemSort.realPathAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.realPath);
        case RecognizeFaceItemSort.realPathDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.realPath);
        case RecognizeFaceItemSort.isFavoriteAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.isFavorite);
        case RecognizeFaceItemSort.isFavoriteDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.isFavorite);
        case RecognizeFaceItemSort.fileMetadataWidthAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.fileMetadataWidth);
        case RecognizeFaceItemSort.fileMetadataWidthDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.fileMetadataWidth);
        case RecognizeFaceItemSort.fileMetadataHeightAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.fileMetadataHeight);
        case RecognizeFaceItemSort.fileMetadataHeightDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.fileMetadataHeight);
        case RecognizeFaceItemSort.faceDetectionsAsc:
          return OrderingTerm.asc(db.recognizeFaceItems.faceDetections);
        case RecognizeFaceItemSort.faceDetectionsDesc:
          return OrderingTerm.desc(db.recognizeFaceItems.faceDetections);
      }
    });
  }
}
