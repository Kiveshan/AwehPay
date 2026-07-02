const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');

// SES client. Region + credentials come from the environment:
// - AWS_REGION (must match the region where the domain is verified)
// - On Elastic Beanstalk: the EC2 instance role supplies credentials automatically.
// - Locally: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY from .env.
const sesClient = new SESClient({ region: process.env.AWS_REGION || 'eu-west-1' });

const FROM_EMAIL = process.env.SES_FROM_EMAIL || 'receipts@awehpay.co.za';

function formatRand(value) {
  const n = typeof value === 'number' ? value : parseFloat(value) || 0;
  return `R${n.toFixed(2)}`;
}

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildItemRows(items) {
  return (items || [])
    .map((item) => {
      const qty = item.quantity ?? 1;
      const unit = item.unitPrice ?? 0;
      const lineTotal = item.totalPrice ?? unit * qty;
      return `
        <tr>
          <td style="padding:8px 0;color:#272A2F;">${escapeHtml(item.name)} &times;${qty}</td>
          <td style="padding:8px 0;text-align:right;color:#272A2F;">${formatRand(lineTotal)}</td>
        </tr>`;
    })
    .join('');
}

function buildHtml({
  businessName,
  items,
  amountSubtotal,
  amountTax,
  amountTotal,
  amountCollected,
  amountChange,
  paymentMethod,
  transactionId,
}) {
  const isCash = paymentMethod === 'cash';
  return `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#272A2F;">
    <h2 style="margin:0 0 4px;color:#6C5CE7;">${escapeHtml(businessName || 'AwehPay')}</h2>
    <p style="margin:0 0 20px;color:#9B9B9B;font-size:13px;">Payment receipt</p>

    <table style="width:100%;border-collapse:collapse;font-size:14px;">
      ${buildItemRows(items)}
    </table>

    <hr style="border:none;border-top:1px solid #E0E0E0;margin:16px 0;" />

    <table style="width:100%;border-collapse:collapse;font-size:14px;">
      <tr><td style="padding:4px 0;">Subtotal</td><td style="padding:4px 0;text-align:right;">${formatRand(amountSubtotal)}</td></tr>
      <tr><td style="padding:4px 0;">VAT (15%)</td><td style="padding:4px 0;text-align:right;">${formatRand(amountTax)}</td></tr>
      <tr><td style="padding:8px 0;font-weight:bold;">Total</td><td style="padding:8px 0;text-align:right;font-weight:bold;">${formatRand(amountTotal)}</td></tr>
      ${isCash ? `
      <tr><td style="padding:4px 0;color:#9B9B9B;">Amount collected</td><td style="padding:4px 0;text-align:right;color:#9B9B9B;">${formatRand(amountCollected)}</td></tr>
      <tr><td style="padding:4px 0;color:#9B9B9B;">Change</td><td style="padding:4px 0;text-align:right;color:#9B9B9B;">${formatRand(amountChange)}</td></tr>` : ''}
    </table>

    <hr style="border:none;border-top:1px solid #E0E0E0;margin:16px 0;" />

    <p style="font-size:12px;color:#9B9B9B;margin:0;">
      Payment method: ${escapeHtml(paymentMethod || 'card')}<br/>
      Reference: ${escapeHtml(transactionId || '')}
    </p>
    <p style="font-size:12px;color:#9B9B9B;margin:16px 0 0;">Thank you for your purchase.</p>
  </div>`;
}

function buildText({ businessName, amountTotal, transactionId }) {
  return `${businessName || 'AwehPay'} - Payment receipt\n\nTotal: ${formatRand(amountTotal)}\nReference: ${transactionId || ''}\n\nThank you for your purchase.`;
}

/**
 * Send a receipt email via AWS SES. Best-effort: resolves with { sent: false }
 * on any failure instead of throwing, so a failed email never breaks a payment.
 */
async function sendReceiptEmail(params) {
  const { toEmail } = params;

  if (!toEmail || !toEmail.includes('@')) {
    return { sent: false, reason: 'no valid recipient email' };
  }

  try {
    const command = new SendEmailCommand({
      Source: FROM_EMAIL,
      Destination: { ToAddresses: [toEmail] },
      Message: {
        Subject: {
          Data: `Your receipt from ${params.businessName || 'AwehPay'}`,
          Charset: 'UTF-8',
        },
        Body: {
          Html: { Data: buildHtml(params), Charset: 'UTF-8' },
          Text: { Data: buildText(params), Charset: 'UTF-8' },
        },
      },
    });

    const result = await sesClient.send(command);
    return { sent: true, messageId: result.MessageId };
  } catch (error) {
    console.error('send_receipt error:', error.message);
    return { sent: false, reason: error.message };
  }
}

module.exports = { sendReceiptEmail };
