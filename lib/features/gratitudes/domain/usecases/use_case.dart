// lib/features/gratitudes/domain/usecases/use_case.dart

/// Base interface for all use cases in the application
///
/// Provides consistent structure and makes use cases predictable.
/// Each use case should do ONE thing and do it well (Single Responsibility).
///
/// Type parameters:
/// - [T]: The return type of the use case
/// - [Params]: The parameters required to execute the use case
abstract class UseCase<T, Params> {
  /// Execute the use case with given parameters
  Future<T> call(Params params);
}

/// Use this when a use case doesn't need parameters
class NoParams {
  const NoParams();
}