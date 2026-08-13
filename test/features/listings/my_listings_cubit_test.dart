import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/listings/data/listing_repository.dart';
import 'package:nipanze/features/listings/domain/models/my_listing.dart';
import 'package:nipanze/features/listings/presentation/cubit/my_listings_cubit.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late MockListingRepository mockRepo;

  final testListing = MyListing(
    id: 'req-1',
    title: 'School fees',
    purpose: 'Education',
    district: 'Kampala',
    durationMonths: 6,
    requestedAmount: 1000000,
    incomeSource: 'Salary',
    preferredRepaymentPlan: 'Monthly',
    repaymentAmountPerPeriod: 200000,
    repaymentTimeline: '6 months',
    status: ListingStatus.active,
    numberOfOffers: 0,
    listedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  setUp(() {
    mockRepo = MockListingRepository();
    when(() => mockRepo.getMyListings())
        .thenAnswer((_) async => [testListing]);
    when(() => mockRepo.cancelListing(any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.watchMyListings())
        .thenAnswer((_) => Stream.value([testListing]));
  });

  test('cancelListing reloads listings after a successful cancellation', () async {
    final cubit = MyListingsCubit(mockRepo);

    await cubit.load();
    await cubit.cancelListing('req-1');

    verify(() => mockRepo.getMyListings()).called(2);
    expect(cubit.state, isA<MyListingsLoaded>());
  });
}
