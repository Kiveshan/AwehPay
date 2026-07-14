import 'package:flutter/material.dart';
import '../../system_admin/views/widgets/admin_scaffold.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Terms and Conditions',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AwehBiz Terms and Conditions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Effective Date: 13 July 2026',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Welcome to AwehBiz',
                'A cloud-based mobile application for Point of Sale, Inventory Control, and Analytics, owned, operated, and maintained by SmartBuilders (Pty) Ltd ("SmartBuilders", "we", "our", or "us"). By registering a business account, creating a user account, downloading, accessing, or using the AwehBiz application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree with these Terms, you must not create an account or use the application.\n\nIf you accept these Terms on behalf of a company or other legal entity, you represent and warrant that you are authorised to bind that entity to these Terms.',
              ),
              _buildSection(
                '1. About AwehBiz',
                'AwehBiz is a cloud-based mobile application designed for small traders to manage Point of Sale (POS) transactions, inventory control, and business analytics.\n\nAwehBiz is a software platform developed, owned, and operated by SmartBuilders (Pty) Ltd, and is made available to Customers on a subscription basis. SmartBuilders (Pty) Ltd provides the software only and is not a payment processor, merchant acquirer, or a party to any Customer\'s commercial transactions with its own customers.',
              ),
              _buildSection(
                '2. Eligibility and Account Registration',
                'By registering an account, you confirm that:\n• You are at least 18 years of age.\n• You are authorised to act on behalf of, and to bind, the Customer you represent.\n• All information you provide is accurate, current, and complete.\n• You will keep your account credentials secure and confidential.\n• You are responsible for all activity conducted through your account and by your Authorised Users.\n\nBusiness account registrations may be subject to review and approval by SmartBuilders (Pty) Ltd before access is activated. We may decline or revoke a registration at our discretion where necessary to protect the platform or comply with legal obligations.',
              ),
              _buildSection(
                '3. Subscription, Fees and Payment',
                'Access to the Service is provided on a paid subscription basis. By subscribing to AwehBiz, the Customer acknowledges and agrees that:\n\n**Setup Fee.** There is no setup fee for AwehBiz. The Service is available on a monthly subscription basis only.\n\n**Monthly Fee.** A recurring monthly subscription fee is payable in advance for each billing cycle, based on the selected plan:\n• Basic Plan: R300 per month.\n• Premium Plan: R500 per month.\n\n**30-Day Free Trial.** New users are eligible for a 30-day free trial of the Premium Plan. At the end of the trial period, the subscription will automatically convert to a paid Premium Plan unless the Customer cancels before the trial ends.\n\n**Billing cycle.** The Subscription renews automatically each month until cancelled in accordance with these Terms. The billing date is the date on which the Subscription is first activated, or as otherwise agreed in writing.\n\n**Payment method.** Subscription Fees are billed and paid outside the Service, directly between the Customer and SmartBuilders (Pty) Ltd. The Service does not process, collect, or store any payment or card details for subscription fees.\n\n**Taxes.** All fees are exclusive of Value-Added Tax (VAT), which will be applied where applicable.\n\n**Late or non-payment.** Where a fee is not paid when due, SmartBuilders (Pty) Ltd may suspend or restrict access to the Service after 7 days\' written notice, without prejudice to any other rights.\n\n**Refunds.** Fees, including Monthly Fees already paid, are non-refundable except where required by applicable law. No pro-rata refund is provided for a partial billing period on cancellation.\n\n**Price changes.** SmartBuilders (Pty) Ltd may amend the fees on at least 30 days\' written notice. Continued use of the Service after the change takes effect constitutes acceptance of the revised fees.',
              ),
              _buildSection(
                '4. Customer Responsibilities',
                'The Customer agrees that it:\n• is responsible for the accuracy, quality, and legality of all Customer Data (including product information, pricing, and customer details) it submits to the Service;\n• will use the Service in compliance with all applicable South African laws and regulations, including consumer protection and data-protection laws;\n• is responsible for managing its Authorised Users and their access rights;\n• will maintain the confidentiality of its account credentials and notify SmartBuilders (Pty) Ltd promptly of any unauthorised use of, or access to, the Service;\n• will obtain any consents or authorisations required to submit customer or employee Personal Information to the Service;\n• remains solely responsible for its own business operations, tax obligations, and regulatory compliance; and\n• will not rely on the Service as a substitute for its own legal or regulatory obligations.',
              ),
              _buildSection(
                '5. Acceptable Use and Prohibited Activities',
                'Users may not:\n• use the platform for any unlawful purpose;\n• submit false, fraudulent, or misleading information;\n• attempt to gain unauthorised access to AwehBiz systems or other Customers\' data;\n• interfere with or disrupt the platform\'s operation or security;\n• upload malicious software or code;\n• copy, resell, sublicense, or otherwise commercially exploit the Service without authorisation;\n• reverse engineer, decompile, or attempt to derive the source code of the Service; or\n• misrepresent themselves or their authority to use the Service.\n\nViolation of these Terms may result in immediate suspension or permanent termination of the account.',
              ),
              _buildSection(
                '6. Customer Data and Privacy',
                'Your use of AwehBiz is also governed by the AwehBiz Privacy Policy. In respect of Personal Information submitted to the Service, the Customer is the Responsible Party and SmartBuilders (Pty) Ltd acts as an Operator, processing such data only to provide the Service and on the Customer\'s documented instructions, in accordance with the Protection of Personal Information Act, 2013 (POPIA).\n\nThe Customer warrants that it has a lawful basis, and any necessary consent, to collect and submit such Personal Information to the Service, and that it will comply with its obligations as a Responsible Party under applicable privacy legislation.',
              ),
              _buildSection(
                '7. Intellectual Property',
                'All AwehBiz branding, logos, software, source code, designs, graphics, content, documentation, and technology are the exclusive intellectual property of SmartBuilders (Pty) Ltd, unless otherwise stated. Subject to these Terms and payment of the applicable fees, the Customer is granted a limited, non-exclusive, non-transferable, revocable right to access and use the Service for its internal business purposes for the duration of the Subscription. Users may not copy, reproduce, modify, distribute, reverse engineer, sublicense, or commercially exploit any part of the platform without prior written permission from SmartBuilders (Pty) Ltd.\n\nCustomer Data (including product lists, sales records, and business analytics) remains the property of the Customer. The Customer grants SmartBuilders (Pty) Ltd the right to host, process, and use Customer Data solely to provide and improve the Service.',
              ),
              _buildSection(
                '8. Limitation of Liability',
                'To the fullest extent permitted by South African law, SmartBuilders (Pty) Ltd shall not be liable for any:\n• loss of profits, revenue, or business opportunities;\n• loss of, or corruption to, data (except to the extent caused by our gross negligence);\n• operational, regulatory, or compliance failures of the Customer;\n• costs, fines, or penalties arising from the Customer\'s business operations, including but not limited to tax, pricing, or consumer protection matters;\n• indirect, incidental, special, or consequential damages;\n• losses arising from the Customer\'s reliance on the Service in place of its own legal obligations.\n\nTo the maximum extent permitted by law, the total aggregate liability of SmartBuilders (Pty) Ltd arising out of or in connection with the Service shall not exceed the total fees paid by the Customer in the three (3) months preceding the event giving rise to the claim. AwehBiz provides the technology platform only and is not responsible for the Customer\'s operational decisions or business outcomes.',
              ),
              _buildSection(
                '9. Account Suspension and Termination',
                'SmartBuilders (Pty) Ltd reserves the right to suspend, restrict, or permanently terminate accounts that:\n• violate these Terms;\n• engage in fraudulent activity;\n• fail to pay applicable fees;\n• misuse the platform;\n• harm other users; or\n• create legal, financial, operational, or reputational risk to SmartBuilders (Pty) Ltd.\n\nA Customer may cancel its Subscription by providing 30 days\' written notice. Suspension or termination may occur without prior notice where necessary to protect the platform or comply with legal obligations. On termination, access to the Service will cease and Customer Data will be handled in accordance with the Privacy Policy — available for export for a reasonable period and then deleted, unless retention is required by law.',
              ),
              _buildSection(
                '10. Indemnity',
                'The Customer agrees to indemnify, defend, and hold harmless SmartBuilders (Pty) Ltd, its directors, officers, employees, contractors, affiliates, and agents against any claims, losses, liabilities, damages, costs, or legal expenses arising from:\n• the Customer\'s use of the Service;\n• the Customer\'s business operations, including sales, pricing, or tax matters;\n• the Customer\'s breach of these Terms;\n• the Customer\'s violation of any law, including data-protection law; or\n• claims made by the Customer\'s customers, employees, or third parties.',
              ),
              _buildSection(
                '11. Force Majeure',
                'Neither party shall be liable for delays or failures resulting from events beyond its reasonable control, including but not limited to:\n• natural disasters\n• government actions\n• internet or hosting outages\n• cyberattacks\n• power failures\n• labour disputes\n• pandemics\n• civil unrest\n• telecommunications failures',
              ),
              _buildSection(
                '12. Changes to These Terms',
                'SmartBuilders (Pty) Ltd may amend or update these Terms and Conditions from time to time. Updated versions will be published on the AwehBiz platform. Continued use of the platform after changes become effective constitutes acceptance of the revised Terms.',
              ),
              _buildSection(
                '13. Governing Law',
                'These Terms shall be governed by and interpreted in accordance with the laws of the Republic of South Africa. Any dispute arising from these Terms or the use of the AwehBiz platform shall be subject to the exclusive jurisdiction of the courts of South Africa.',
              ),
              _buildSection(
                '14. Contact Information',
                'For questions regarding these Terms and Conditions, please contact:\n\nSmartBuilders (Pty) Ltd\nEmail: info@smart-builders.co.za\nWebsite: https://www.smart-builders.co.za/',
              ),
              _buildSection(
                '15. Acceptance',
                'By registering an AwehBiz account, you confirm that:\n• You have read and understood these Terms and Conditions.\n• You agree to comply with them.\n• You understand that AwehBiz is a technology platform owned and operated by SmartBuilders (Pty) Ltd and is provided "as a service" and not as a substitute for the Customer\'s own legal, operational, or regulatory obligations.\n• You agree to pay the applicable recurring Monthly Fee for your chosen Subscription plan.\n• You acknowledge that fees are non-refundable except where required by law.\n• You acknowledge that your continued use of AwehBiz constitutes acceptance of these Terms and Conditions.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
