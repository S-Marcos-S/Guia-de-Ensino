import 'dart:async';
import 'dart:convert';

import 'package:app/infrastructure/sync/client/sync_api_client.dart';
import 'package:app/infrastructure/sync/client/sync_exceptions.dart';
import 'package:app/infrastructure/sync/models/pull_query_dto.dart';
import 'package:app/infrastructure/sync/models/push_request_dto.dart';
import 'package:app/infrastructure/sync/models/sync_operation_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const testBaseUrl = 'https://api.guiadeensino.test';
  const testToken = 'jwt-mock-token-abc123xyz';

  group('SyncApiClient - Push', () {
    test(
      'deve executar Push com sucesso e anexar cabeçalhos de autenticação',
      () async {
        late http.Request capturedRequest;

        final mockClient = MockClient((request) async {
          capturedRequest = request as http.Request;
          expect(request.method, equals('POST'));
          expect(request.url.toString(), equals('$testBaseUrl/api/sync/push'));
          expect(request.headers['Authorization'], equals('Bearer $testToken'));
          expect(request.headers['Content-Type'], contains('application/json'));

          final responseBody = {
            'clientBatchId': 'batch-1',
            'serverEpoch': '1',
            'currentServerSeq': '10',
            'acks': [
              {
                'clientOpId': 'op-1',
                'status': 'APPLIED',
                'serverSeq': '10',
                'appliedAt': '2026-10-20T14:30:00.000Z',
                'conflict': null,
              },
            ],
          };

          return http.Response(jsonEncode(responseBody), 200);
        });

        final client = SyncApiClient(
          baseUrl: '$testBaseUrl/', // Deve normalizar a barra final
          httpClient: mockClient,
          tokenProvider: () => testToken,
        );

        final pushRequest = PushRequestDto(
          deviceId: 'dev-1',
          clientBatchId: 'batch-1',
          operations: [
            SyncOperationDto(
              clientOpId: 'op-1',
              entityType: 'subject',
              entityId: 'sub-1',
              mutationType: 'INSERT',
              payload: {'name': 'Artes'},
            ),
          ],
        );

        final response = await client.push(pushRequest);

        expect(response.clientBatchId, equals('batch-1'));
        expect(response.currentServerSeq, equals('10'));
        expect(response.acks.length, equals(1));
        expect(response.acks.first.isApplied, isTrue);

        final sentJson =
            jsonDecode(capturedRequest.body) as Map<String, dynamic>;
        expect(sentJson['deviceId'], equals('dev-1'));
      },
    );

    test(
      'deve rejeitar Push antes do envio se requisição for inválida',
      () async {
        final client = SyncApiClient(
          baseUrl: testBaseUrl,
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );

        final invalidRequest = PushRequestDto(
          deviceId: 'dev-1',
          clientBatchId: 'batch-1',
          operations: const [],
        );

        expect(() => client.push(invalidRequest), throwsArgumentError);
      },
    );

    test('deve lançar SyncUnauthorizedException ao receber HTTP 401', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 401,
            'message': 'Token JWT expirado ou ausente.',
          }),
          401,
        );
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final pushRequest = PushRequestDto(
        deviceId: 'dev-1',
        clientBatchId: 'batch-1',
        operations: [
          SyncOperationDto(
            clientOpId: 'op-1',
            entityType: 'subject',
            entityId: 'sub-1',
            mutationType: 'INSERT',
          ),
        ],
      );

      expect(
        () => client.push(pushRequest),
        throwsA(
          isA<SyncUnauthorizedException>().having(
            (e) => e.message,
            'message',
            contains('Token JWT expirado'),
          ),
        ),
      );
    });

    test('deve lançar SyncConflictException ao receber HTTP 409 (Idempotência ou Conflito Concorrente)', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 409,
            'error': 'IdempotencyConflictException',
            'message': 'Payload divergente para client_op_id existente.',
          }),
          409,
        );
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final pushRequest = PushRequestDto(
        deviceId: 'dev-1',
        clientBatchId: 'batch-1',
        operations: [
          SyncOperationDto(
            clientOpId: 'op-dup',
            entityType: 'subject',
            entityId: 'sub-1',
            mutationType: 'INSERT',
          ),
        ],
      );

      expect(
        () => client.push(pushRequest),
        throwsA(
          isA<SyncConflictException>().having(
            (e) => e.message,
            'message',
            contains('Payload divergente'),
          ),
        ),
      );
    });

    test(
      'deve lançar SyncFactualIntegrityException ao receber HTTP 422',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'statusCode': 422,
              'error': 'FactualIntegrityException',
              'message': 'Registros de aula realizada não podem ser excluídos.',
            }),
            422,
          );
        });

        final client = SyncApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        final pushRequest = PushRequestDto(
          deviceId: 'dev-1',
          clientBatchId: 'batch-1',
          operations: [
            SyncOperationDto(
              clientOpId: 'op-delete-diary',
              entityType: 'lesson_execution_record',
              entityId: 'rec-1',
              mutationType: 'DELETE',
            ),
          ],
        );

        expect(
          () => client.push(pushRequest),
          throwsA(
            isA<SyncFactualIntegrityException>().having(
              (e) => e.message,
              'message',
              contains('não podem ser excluídos'),
            ),
          ),
        );
      },
    );
  });

  group('SyncApiClient - Pull', () {
    test(
      'deve executar Pull com sucesso e query parameters corretos',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.path, equals('/api/sync/pull'));
          expect(request.url.queryParameters['cursor'], equals('15:1042'));
          expect(request.url.queryParameters['limit'], equals('50'));
          expect(
            request.url.queryParameters['excludeDeviceId'],
            equals('dev-mobile'),
          );
          expect(request.url.queryParameters['clientEpoch'], equals('1'));

          final responseBody = {
            'epoch': '1',
            'currentServerSeq': '45',
            'nextCursor': '20:1060',
            'hasMore': false,
            'changes': [
              {
                'serverSeq': '16',
                'changeLogId': '1043',
                'entityType': 'classroom',
                'entityId': 'c-1',
                'mutationType': 'INSERT',
                'payload': {'name': 'Turma 7B'},
                'deviceId': 'web-1',
                'createdAt': '2026-10-20T14:32:00.000Z',
              },
            ],
          };

          return http.Response(jsonEncode(responseBody), 200);
        });

        final client = SyncApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        final response = await client.pull(
          const PullQueryDto(
            cursor: '15:1042',
            limit: 50,
            excludeDeviceId: 'dev-mobile',
            clientEpoch: '1',
          ),
        );

        expect(response.epoch, equals('1'));
        expect(response.currentServerSeq, equals('45'));
        expect(response.nextCursor, equals('20:1060'));
        expect(response.hasMore, isFalse);
        expect(response.changes.length, equals(1));
        expect(response.changes.first.entityType, equals('classroom'));
      },
    );

    test('deve lançar SyncResyncRequiredException ao receber HTTP 410 (RESYNC_REQUIRED)', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 410,
            'code': 'RESYNC_REQUIRED',
            'serverEpoch': '2',
            'message':
                'Época de sincronização divergente. Full Resync obrigatório.',
          }),
          410,
        );
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      expect(
        () => client.pull(const PullQueryDto(clientEpoch: '1')),
        throwsA(
          isA<SyncResyncRequiredException>()
              .having((e) => e.serverEpoch, 'serverEpoch', equals('2'))
              .having(
                (e) => e.errorCode,
                'errorCode',
                equals('RESYNC_REQUIRED'),
              ),
        ),
      );
    });

    test('deve lançar SyncInvalidCursorException ao receber HTTP 400 (INVALID_CURSOR)', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 400,
            'code': 'INVALID_CURSOR',
            'requestedSeq': '999',
            'currentServerSeq': '45',
            'message': 'Cursor excede a sequência atual do servidor.',
          }),
          400,
        );
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      expect(
        () => client.pull(const PullQueryDto(cursor: '999:0')),
        throwsA(
          isA<SyncInvalidCursorException>()
              .having((e) => e.requestedSeq, 'requestedSeq', equals('999'))
              .having(
                (e) => e.currentServerSeq,
                'currentServerSeq',
                equals('45'),
              ),
        ),
      );
    });
  });

  group('SyncApiClient - Snapshot', () {
    test('deve baixar snapshot consistente com sucesso', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/sync/snapshot'));
        expect(request.url.queryParameters['snapshotToken'], equals('tok-xyz'));

        final responseBody = {
          'epoch': '1',
          'snapshotSeq': '100',
          'snapshotToken': 'tok-xyz',
          'expiresAt': '2026-10-20T14:45:00.000Z',
          'entities': {
            'academic_years': [
              {'id': 'ay-1', 'year': 2026},
            ],
            'classrooms': [],
            'subjects': [],
            'classroom_subjects': [],
            'school_calendar_events': [],
            'schedule_slots': [],
            'curriculum_competencies': [],
            'course_contents': [],
            'content_prerequisites': [],
            'planned_lessons': [],
            'lesson_content_allocations': [],
            'lesson_execution_records': [],
            'execution_content_allocations': [],
          },
        };

        return http.Response(jsonEncode(responseBody), 200);
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      final snapshot = await client.getSnapshot(snapshotToken: 'tok-xyz');
      expect(snapshot.snapshotSeq, equals('100'));
      expect(snapshot.entities.academicYears.length, equals(1));
    });

    test('deve lançar SyncSnapshotExpiredException ao receber HTTP 410 (SNAPSHOT_EXPIRED)', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 410,
            'code': 'SNAPSHOT_EXPIRED',
            'message': 'O token do snapshot expirou.',
          }),
          410,
        );
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      expect(
        () => client.getSnapshot(snapshotToken: 'tok-expired'),
        throwsA(isA<SyncSnapshotExpiredException>()),
      );
    });
  });

  group('SyncApiClient - Resiliência e Falhas de Transporte', () {
    test('deve converter TimeoutException em SyncTimeoutException', () async {
      final mockClient = MockClient((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        () => client.pull(const PullQueryDto()),
        throwsA(isA<SyncTimeoutException>()),
      );
    });

    test('deve converter ClientException em SyncNetworkException', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });

      final client = SyncApiClient(
        baseUrl: testBaseUrl,
        httpClient: mockClient,
      );

      expect(
        () => client.pull(const PullQueryDto()),
        throwsA(
          isA<SyncNetworkException>().having(
            (e) => e.message,
            'message',
            contains('Connection refused'),
          ),
        ),
      );
    });

    test(
      'deve converter resposta com JSON corrompido em SyncServerException',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response('<!DOCTYPE html><html>Erro 502</html>', 200);
        });

        final client = SyncApiClient(
          baseUrl: testBaseUrl,
          httpClient: mockClient,
        );

        expect(
          () => client.pull(const PullQueryDto()),
          throwsA(
            isA<SyncServerException>().having(
              (e) => e.message,
              'message',
              contains('JSON válido'),
            ),
          ),
        );
      },
    );
  });
}
