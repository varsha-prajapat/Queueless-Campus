class Api_Config {
  static const String base_Url = String.fromEnvironment(
    "BASE_URL",
    defaultValue: "http://localhost:3005",
  );
  static const String Api_Prefix = String.fromEnvironment(
    "API_PREFIX",
    defaultValue: "/api/v1",
  );
  static const String register = "$base_Url$Api_Prefix/auth/register";
  static const String login = "$base_Url$Api_Prefix/auth/login";
  static const String otp = "$base_Url$Api_Prefix/auth/otp";
  static const String refresh = "$base_Url$Api_Prefix/auth/refresh";

  // 👤 USER / PROFILE
  static const String getMyProfile = "$base_Url$Api_Prefix/common/me";
  static const String updateMyProfile = "$base_Url$Api_Prefix/common/me";

  static const String inviteUser = "$base_Url$Api_Prefix/admin/register-invite";

  static const String department = "$base_Url$Api_Prefix/admin/department";

  static const String commondepartment = "$base_Url$Api_Prefix/departments";

  static const String service = "$base_Url$Api_Prefix/admin/service";

  static const String banner = "$base_Url$Api_Prefix/admin/banner";
  static const String banner_all = "$base_Url$Api_Prefix/common/banner";

  static const String notifications =
      "$base_Url$Api_Prefix/common/notifications";

  static const String users_admin = "$base_Url$Api_Prefix/admin";
  static const String counter = "$base_Url$Api_Prefix/admin/counter";
  static const String service_active = "$base_Url$Api_Prefix/common/service";
  static const String assign_counter =
      "$base_Url$Api_Prefix/admin/assign-counter";
  static const String staff_department = "$base_Url$Api_Prefix/admin/staff";

  static const String department_infor =
      "$base_Url$Api_Prefix/common/department";

  static const String getcounter_staff = "$base_Url$Api_Prefix/staff/counter";

  static const String getservice_name = "$base_Url$Api_Prefix/common/service";

  static const String token_staff = "$base_Url$Api_Prefix/staff/stats";

  static const String book_token = "$base_Url$Api_Prefix/student/token";

  static const String token_payment =
      "$base_Url$Api_Prefix/student/token/payment/confirm";

  static const String token_stats = "$base_Url$Api_Prefix/student/token/stats";

  static const String service_student = "$base_Url$Api_Prefix/student/services";

  static const String my_tokens =
      "$base_Url$Api_Prefix/student/token/my-tokens";

  static const String admin_contact = "$base_Url$Api_Prefix";

  static const String all_tokens_details =
      "$base_Url$Api_Prefix/staff/stats/detailed";

  static const String change_token_status_completed =
      "$base_Url$Api_Prefix/staff/token/complete";

  static const String skip_token = "$base_Url$Api_Prefix/staff/token/skip";
  static const String call_token = "$base_Url$Api_Prefix/staff/call-next";

  static const String cancel_token =
      "$base_Url$Api_Prefix/student/token/cancel";

  static const String token_dashboard_admin =
      "$base_Url$Api_Prefix/admin/dashboardtoken";
}
