import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../widgets/shared_widgets.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final wallet = controller.bootstrap!.wallet;
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColours.green700, AppColours.green900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 7),
                Text(
                  formatNaira(wallet.balanceKobo),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showFundingSheet(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColours.green800,
                        ),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Fund wallet'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          side: BorderSide(color: Colors.white.withValues(alpha: .45)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Transactions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 10),
          Row(
            children: [
              _WalletAction(
                icon: Icons.push_pin_outlined,
                label: 'Buy pin',
                onTap: () {},
              ),
              _WalletAction(
                icon: Icons.quiz_outlined,
                label: 'Mock test',
                onTap: () {},
              ),
              _WalletAction(
                icon: Icons.diamond_outlined,
                label: 'Premium',
                onTap: () {},
              ),
              _WalletAction(
                icon: Icons.group_add_outlined,
                label: 'Refer',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 25),
          const SectionHeader(title: 'Recent transactions', actionLabel: 'See all'),
          const SizedBox(height: 9),
          Card(
            child: Column(
              children: wallet.transactions.indexed.map((entry) {
                final index = entry.$1;
                final item = entry.$2;
                final isCredit = item.amountKobo > 0;
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: index == wallet.transactions.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Color(0xFFEDF0EE)),
                          ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColours.mint,
                        foregroundColor: AppColours.green700,
                        child: Icon(
                          isCredit
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${item.date.day}/${item.date.month}/${item.date.year}',
                              style: const TextStyle(fontSize: 12, color: AppColours.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatNaira(item.amountKobo),
                        style: TextStyle(
                          color: isCredit ? AppColours.green700 : AppColours.danger,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(15),
              leading: Icon(Icons.verified_user_outlined, color: AppColours.green700),
              title: Text('Secure server-verified funding'),
              subtitle: Text(
                'The app never contains Paystack secret keys or credits a wallet locally.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFundingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fund wallet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Enter the amount you want to add through Paystack.'),
            const SizedBox(height: 16),
            const TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₦ ',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paystack funding endpoint is ready to be connected.'),
                    ),
                  );
                },
                child: const Text('Continue securely'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: AppColours.mint,
                  foregroundColor: AppColours.green700,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      );
}
