import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/payslip_models.dart';
import '../domain/payslip_repository.dart';

const String _base = '/italian-payroll/my-payslips';

PayslipException mapPayslipError(DioException e) {
  final int? status = e.response?.statusCode;
  return switch (status) {
    null => const PayslipException(PayslipErrorKind.offline),
    401 => const PayslipException(PayslipErrorKind.unauthorized),
    403 => const PayslipException(PayslipErrorKind.forbidden),
    404 => const PayslipException(PayslipErrorKind.notFound),
    _ => PayslipException(PayslipErrorKind.unknown, '$status'),
  };
}

class PayslipRepositoryImpl implements PayslipRepository {
  PayslipRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<PayslipEntry>> list() async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(_base);
      final dynamic body = r.data;
      final dynamic data = body is Map ? body['data'] : body;
      if (data is! List) {
        throw const PayslipException(PayslipErrorKind.unknown, 'no data');
      }
      return <PayslipEntry>[
        for (final dynamic row in data)
          if (row is Map) PayslipEntry.fromJson(Map<String, dynamic>.from(row)),
      ];
    } on DioException catch (e) {
      throw mapPayslipError(e);
    }
  }

  @override
  Future<Uint8List> open(
    String distributionId,
    PayslipKind kind, {
    required bool biometricConfirmed,
  }) async {
    try {
      final Response<List<int>> r = await _dio.post<List<int>>(
        '$_base/$distributionId/open',
        data: <String, dynamic>{
          'document_kind': kind.wire,
          'biometric_confirmed': biometricConfirmed,
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: <String, dynamic>{'Accept': 'application/pdf'},
        ),
      );
      final List<int>? bytes = r.data;
      if (bytes == null || bytes.isEmpty) {
        throw const PayslipException(PayslipErrorKind.unknown, 'empty');
      }
      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw mapPayslipError(e);
    }
  }
}
