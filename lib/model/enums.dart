enum ChannelEnum { xiaomi, tencent, huawei, honor, oppo, vivo }

enum AuditStatus {
  known("未知"),
  auditing("审核中"),
  auditFailed("审核失败"),
  auditSuccess("审核成功");

  final String name;

  const AuditStatus(this.name);
}
