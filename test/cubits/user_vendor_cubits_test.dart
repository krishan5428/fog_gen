// ignore_for_file: non_constant_identifier_names
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/data/pojo/user_data.dart';
import 'package:fog_gen_new/core/data/pojo/vendor_data.dart';
import 'package:fog_gen_new/core/repo/user_repo.dart';
import 'package:fog_gen_new/core/repo/vendor_repo.dart';
import 'package:fog_gen_new/core/responses/add_vendor_response.dart';
import 'package:fog_gen_new/core/responses/del_user_response.dart';
import 'package:fog_gen_new/core/responses/del_vendor_response.dart';
import 'package:fog_gen_new/core/responses/forgot_pass_response.dart';
import 'package:fog_gen_new/core/responses/get_vendor_response.dart';
import 'package:fog_gen_new/core/responses/login_response.dart';
import 'package:fog_gen_new/core/responses/signup_response.dart';
import 'package:fog_gen_new/core/responses/update_user_response.dart';
import 'package:fog_gen_new/presentation/cubit/forgotPass/forget_pswd_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/forgotPass/forgot_pass_state.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/mappings/site_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/user/user_cubit.dart';
import 'package:fog_gen_new/presentation/cubit/vendor/vendor_cubit.dart';

UserData user() => UserData.fromJson({'usr_id': 5, 'name': 'A'});

class FakeUserRepo extends Fake implements UserRepo {
  LoginResponse login_ = LoginResponse(status: true, token: 't', msg: 'ok');
  bool fail = false;
  String? lastFcm;

  Never _boom() => throw Exception('network down');

  @override
  Future<LoginResponse> login(String m, String p, String fcm) async {
    if (fail) _boom();
    lastFcm = fcm;
    return login_;
  }

  @override
  Future<SignupResponse> signUp(a, b, c, d, e, f) async {
    if (fail) _boom();
    return SignupResponse(status: a != 'dup', msg: a == 'dup' ? '' : 'Done');
  }

  @override
  Future<ForgotPassResponse> forgotPass(String mobile) async {
    if (fail) _boom();
    return ForgotPassResponse(status: mobile == '1', msg: 'm$mobile');
  }

  @override
  Future<UpdateUserResponse> updateValue(a, b, c) async {
    if (fail) _boom();
    return UpdateUserResponse(msg: 'updated');
  }

  @override
  Future<DeleteUserResponse> deleteUser(a, b) async {
    if (fail) _boom();
    return DeleteUserResponse(status: true, msg: 'deleted');
  }
}

class FakeVendorRepo extends Fake implements VendorRepo {
  bool fail = false;
  bool ok = true;

  @override
  Future<GetVendorResponse> getVendor(String userId) async {
    if (fail) throw Exception('x');
    return GetVendorResponse(
      status: ok,
      vendorData: [
        VendorData(
          user_id: userId,
          vendor_name: 'V',
          vendor_email: '',
          vendor_mobile: '1',
          vendor_address: '',
        ),
      ],
    );
  }

  @override
  Future<AddVendorResponse> addVendor(a, b, c, d, e, f) async {
    if (fail) throw Exception('x');
    return AddVendorResponse(
      status: ok,
      msg: ok ? 'added' : 'dup',
      vendorId: 1,
    );
  }

  @override
  Future<DeleteVendorResponse> deleteVendor(String m) async {
    if (fail) throw Exception('x');
    return DeleteVendorResponse(status: ok, msg: ok ? 'gone' : 'missing');
  }
}

/// States emitted by [act] after the cubit's current state.
Future<List<S>> states<S>(
  Stream<S> stream,
  void Function() act, {
  int count = 2,
}) async {
  final f = stream.take(count).toList();
  act();
  return f.timeout(const Duration(seconds: 2));
}

void main() {
  group('UserCubit', () {
    late FakeUserRepo repo;
    late UserCubit cubit;
    setUp(() {
      repo = FakeUserRepo();
      cubit = UserCubit(repo);
    });
    tearDown(() => cubit.close());

    test('login success carries the user; null FCM token sent as ""', () async {
      repo.login_ = LoginResponse(
        status: true,
        token: 't',
        msg: 'ok',
        data: user(),
      );
      final s = await states(cubit.stream, () => cubit.login('9', 'p', null));
      expect(s[0], isA<UserLoading>());
      expect((s[1] as UserLoginSuccess).user.usrId, 5);
      expect((s[1] as UserLoginSuccess).vendorAdded, isFalse);
      expect(repo.lastFcm, '');
    });

    test('login passes vendor_added on to the screen', () async {
      repo.login_ = LoginResponse(
        status: true,
        token: 't',
        msg: 'ok',
        data: user(),
        vendorAdded: true,
      );
      final s = await states(cubit.stream, () => cubit.login('9', 'p', 'x'));
      expect((s[1] as UserLoginSuccess).vendorAdded, isTrue);
    });

    test('login: status true but no user data → failure', () async {
      final s = await states(cubit.stream, () => cubit.login('9', 'p', 'x'));
      expect((s[1] as UserLoginFailure).message, 'ok');
    });

    test('login rejected with empty msg → "Login failed"', () async {
      repo.login_ = LoginResponse(status: false, token: '', msg: '');
      final s = await states(cubit.stream, () => cubit.login('9', 'p', 'x'));
      expect((s[1] as UserLoginFailure).message, 'Login failed');
    });

    test('login network error → failure', () async {
      repo.fail = true;
      final s = await states(cubit.stream, () => cubit.login('9', 'p', 'x'));
      expect(s[1], isA<UserLoginFailure>());
    });

    test('signup success / rejected with empty msg', () async {
      var s = await states(
        cubit.stream,
        () => cubit.signUp(
          name: 'a',
          email: '',
          mobile: '',
          password: '',
          devInfo: '',
          deviceId: '',
        ),
      );
      expect((s[1] as UserSignUpSuccess).message, 'Done');
      s = await states(
        cubit.stream,
        () => cubit.signUp(
          name: 'dup',
          email: '',
          mobile: '',
          password: '',
          devInfo: '',
          deviceId: '',
        ),
      );
      expect((s[1] as UserSignUpFailure).message, 'Signup failed');
    });

    test('forgot password success / failure', () async {
      var s = await states(cubit.stream, () => cubit.forgotPass(mobile: '1'));
      expect(s[1], isA<UserForgotPassSuccess>());
      s = await states(cubit.stream, () => cubit.forgotPass(mobile: '2'));
      expect((s[1] as UserForgotPassFailure).message, 'm2');
    });

    test('update and delete user, and their network errors', () async {
      var s = await states(
        cubit.stream,
        () => cubit.updateUser(userId: '5', value: 'v', key: 'device_id'),
      );
      expect((s[1] as UserUpdateSuccess).message, 'updated');
      s = await states(
        cubit.stream,
        () => cubit.deleteUser(mobile: '9', password: 'p'),
      );
      expect((s[1] as UserDeleteSuccess).message, 'deleted');
      repo.fail = true;
      s = await states(
        cubit.stream,
        () => cubit.updateUser(userId: '5', value: 'v', key: 'k'),
      );
      expect(s[1], isA<UserUpdateFailure>());
      s = await states(
        cubit.stream,
        () => cubit.deleteUser(mobile: '9', password: 'p'),
      );
      expect(s[1], isA<UserDeleteFailure>());
    });
  });

  group('ForgetPswdCubit', () {
    test('empty mobile → error without calling the server', () async {
      final repo = FakeUserRepo()..fail = true;
      final c = ForgetPswdCubit(repository: repo);
      await c.forgetPassword(mobile: '');
      expect(
        c.state,
        const ForgetPswdStateError(error: 'Mobile cannot be empty'),
      );
      await c.close();
    });

    test('success, rejection and network error', () async {
      final repo = FakeUserRepo();
      final c = ForgetPswdCubit(repository: repo);
      await c.forgetPassword(mobile: '1');
      expect(c.state, const ForgetPswdStateSuccess(msg: 'm1'));
      await c.forgetPassword(mobile: '2');
      expect(c.state, const ForgetPswdStateError(error: 'm2'));
      repo.fail = true;
      await c.forgetPassword(mobile: '1');
      expect(
        c.state,
        const ForgetPswdStateError(
          error: 'Something went wrong. Please try again.',
        ),
      );
      await c.close();
    });
  });

  group('VendorCubit', () {
    late FakeVendorRepo repo;
    late VendorCubit cubit;
    setUp(() {
      repo = FakeVendorRepo();
      cubit = VendorCubit(repo);
    });
    tearDown(() => cubit.close());

    test('get vendors: success / "No Data Found" / error', () async {
      var s = await states(cubit.stream, () => cubit.getVendor(userId: '3'));
      expect((s[1] as GetVendorSuccess).vendorData.single.user_id, '3');
      repo.ok = false;
      s = await states(cubit.stream, () => cubit.getVendor(userId: '3'));
      expect((s[1] as GetVendorFailure).message, 'No Data Found');
      repo.fail = true;
      s = await states(cubit.stream, () => cubit.getVendor(userId: '3'));
      expect(s[1], isA<GetVendorFailure>());
    });

    test('add and delete vendor: success and rejection', () async {
      void add() => cubit.addVendor(
        userId: '3',
        vendorName: 'V',
        vendorEmail: '',
        vendorMobile: '1',
        vendorAddress: '',
        createdAt: '',
      );
      var s = await states(cubit.stream, add);
      expect((s[1] as AddVendorSuccess).message, 'added');
      s = await states(cubit.stream, () => cubit.deleteVendor(mobile: '1'));
      expect((s[1] as DeleteVendorSuccess).message, 'gone');
      repo.ok = false;
      s = await states(cubit.stream, add);
      expect((s[1] as AddVendorFailure).message, 'dup');
      s = await states(cubit.stream, () => cubit.deleteVendor(mobile: '1'));
      expect((s[1] as DeleteVendorFailure).message, 'missing');
    });
  });

  test('SiteCubit / PanelSimNumberCubit hold what they are given', () {
    final sites = SiteCubit()..setSites(['A', 'B']);
    final sims = PanelSimNumberCubit()..setPanelSimNumbers(['1']);
    expect(sites.state, ['A', 'B']);
    expect(sims.state, ['1']);
  });
}
