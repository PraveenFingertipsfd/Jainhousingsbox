/**
 * Generic, reusable WhatsApp template sender.
 *
 * Takes a template Custom Metadata developer name (resolved via
 * WhatsAppTemplates.getTemplateName -> SMS_Template__mdt) and a list of phone
 * numbers, and sends the template to each number as a bulk-safe async job.
 *
 * Runs as a Queueable with Database.AllowsCallouts so the HTTP callout happens
 * outside the enqueuing transaction. All per-send logging is buffered by
 * WhatsAppService/ApexLogUtil; this job owns the single ApexLogUtil.flush().
 */
public class SendWhatsAppQueueable implements Queueable, Database.AllowsCallouts {

    private String templateDevName;
    private List<String> phoneNumbers;

    public SendWhatsAppQueueable(String templateDevName, List<String> phoneNumbers) {
        this.templateDevName = templateDevName;
        this.phoneNumbers = phoneNumbers;
    }

    public void execute(QueueableContext context) {
        String templateId = WhatsAppTemplates.getTemplateName(templateDevName);
        if (String.isBlank(templateId)) {
            System.debug('SendWhatsAppQueueable: No template found for ' + templateDevName);
            return;
        }

        try {
            for (String phone : phoneNumbers) {
                if (String.isBlank(phone)) continue;

                String result = WhatsAppService.sendTemplateMessage(phone, templateId, null);

                if (result != null) {
                    System.debug('WhatsApp (' + templateDevName + ') sent to ' + phone);
                } else {
                    System.debug('WhatsApp (' + templateDevName + ') failed for ' + phone);
                }
            }
        } finally {
            // Persist all buffered logs once, after every callout is done
            ApexLogUtil.flush();
        }
    }
}
