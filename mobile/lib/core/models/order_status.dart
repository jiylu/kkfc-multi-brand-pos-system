import 'package:json_annotation/json_annotation.dart';

enum OrderStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('QUEUED')
  queued,
  @JsonValue('ACKNOWLEDGED')
  acknowledged,
  @JsonValue('PREPARING')
  preparing,
  @JsonValue('CHECKING')
  checking,
  @JsonValue('REWORKING')
  reworking,
  @JsonValue('READY')
  ready,
  @JsonValue('HANDED_OVER')
  handedOver,
  @JsonValue('CANCELLED')
  cancelled,
}
