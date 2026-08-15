class AutoSnoozeConfig {
  final bool enabled;
  final int intervalMinutes;
  final int maxSnoozes;

  const AutoSnoozeConfig({
    this.enabled = true,
    this.intervalMinutes = 10,
    this.maxSnoozes = 3,
  });

  AutoSnoozeConfig copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? maxSnoozes,
  }) {
    return AutoSnoozeConfig(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
        'maxSnoozes': maxSnoozes,
      };

  factory AutoSnoozeConfig.fromJson(Map<String, dynamic> json) {
    return AutoSnoozeConfig(
      enabled: json['enabled'] ?? true,
      intervalMinutes: json['intervalMinutes'] ?? 10,
      maxSnoozes: json['maxSnoozes'] ?? 3,
    );
  }
}
