import 'package:flutter_test/flutter_test.dart';
import 'package:eps_topik_app/core/services/auth_service.dart';
import 'package:eps_topik_app/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('User update, registration and login persistence test', () async {
    await StorageService.instance.init();
    AuthService.instance.init();

    // 1. Test Self Registration
    final regOk = AuthService.instance.registerStudent(
      name: 'Hari Bahadur',
      username: 'hari2026',
      password: 'mypassword123',
      mobileNumber: '9811111111',
    );
    expect(regOk, true);

    // Login with new registered student
    final loggedInHari = AuthService.instance.login('hari2026', 'mypassword123');
    expect(loggedInHari != null, true);
    expect(loggedInHari?.username, 'hari2026');

    // 2. Test Admin editing student credentials
    final updateOk = AuthService.instance.updateStudentCredentials(
      studentId: loggedInHari!.id,
      newUsername: 'hari_updated',
      newPassword: 'newpass456',
    );
    expect(updateOk, true);

    // Old credentials should fail
    expect(AuthService.instance.login('hari2026', 'mypassword123'), null);
    // New credentials should succeed
    final loggedInUpdated = AuthService.instance.login('hari_updated', 'newpass456');
    expect(loggedInUpdated != null, true);
    expect(loggedInUpdated?.username, 'hari_updated');

    // 3. Test Super Admin registering Institute Admin
    AuthService.instance.registerInstituteAdmin(
      username: 'everest_admin',
      password: 'everest123',
      name: 'Everest Admin',
      mobileNumber: '9822222222',
      instituteId: 'inst_everest',
      instituteName: 'Everest Institute',
    );

    final loggedInInstAdmin = AuthService.instance.login('everest_admin', 'everest123');
    expect(loggedInInstAdmin != null, true);
    expect(loggedInInstAdmin?.role, UserRole.admin);

    // 4. Test Super Admin credential update
    final superUpdateOk = AuthService.instance.updateUserCredentials(
      userId: 'SUPER_ADMIN_001',
      newPassword: 'supersecret999',
    );
    expect(superUpdateOk, true);

    final loggedInSuper = AuthService.instance.login('superadmin', 'supersecret999');
    expect(loggedInSuper != null, true);
    expect(loggedInSuper?.role, UserRole.superAdmin);
  });
}
