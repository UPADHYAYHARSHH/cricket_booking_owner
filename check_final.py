with open('lib/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart', 'r', encoding='utf-8') as f:
    for line in f:
        if 'todayRevenue:' in line:
            print(repr(line.strip()))
