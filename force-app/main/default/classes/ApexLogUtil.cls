/**
 * Reusable logging utility that persists Apex_Log__c records for every request
 * (success or error) with full detail: input parameters, request, response and
 * error message.
 *
 * Design: buffer-and-flush. Callers add() log entries into an in-memory buffer
 * (no DML), then call flush() ONCE after all callouts in the transaction are
 * done. This avoids "System.CalloutException: You have uncommitted work pending"
 * that would occur if a log were inserted between two callouts in a loop, and
 * keeps the whole transaction to a single DML statement.
 *
 * Declared "without sharing" so logging never fails due to record-level sharing.
 */
public without sharing class ApexLogUtil {

    // Salesforce field limits
    private static final Integer TEXTAREA_MAX = 255;      // Request_Type__c, Status__c
    private static final Integer LONGTEXT_MAX = 131072;   // Error_Message__c, Input_Parameters__c, Request__c, Response__c

    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_ERROR   = 'Error';

    // In-memory buffer of log records pending insert
    private static List<Apex_Log__c> buffer = new List<Apex_Log__c>();

    // ---------------------------------------------------------------------
    // Buffer methods (safe to call between callouts - no DML performed here)
    // ---------------------------------------------------------------------

    /**
     * Core buffer method. Builds an Apex_Log__c (with field-length truncation)
     * and adds it to the buffer. Call flush() afterwards to persist.
     */
    public static void add(String requestType, String status, String inputParams,
                           String request, String response, String errorMessage) {
        buffer.add(new Apex_Log__c(
            Request_Type__c    = truncate(requestType, TEXTAREA_MAX),
            Status__c          = truncate(status, TEXTAREA_MAX),
            Input_Parameters__c = truncate(inputParams, LONGTEXT_MAX),
            Request__c         = truncate(request, LONGTEXT_MAX),
            Response__c        = truncate(response, LONGTEXT_MAX),
            Error_Message__c   = truncate(errorMessage, LONGTEXT_MAX)
        ));
    }

    /** Buffer a success log. */
    public static void logSuccess(String requestType, String inputParams,
                                  String request, String response) {
        add(requestType, STATUS_SUCCESS, inputParams, request, response, null);
    }

    /** Buffer an error log with an explicit error message. */
    public static void logError(String requestType, String inputParams,
                                String request, String response, String errorMessage) {
        add(requestType, STATUS_ERROR, inputParams, request, response, errorMessage);
    }

    /** Buffer an error log from an exception (message + stack trace). */
    public static void logError(String requestType, String inputParams, Exception e) {
        String msg = (e == null)
            ? 'Unknown exception'
            : e.getMessage() + '\n' + e.getStackTraceString();
        add(requestType, STATUS_ERROR, inputParams, null, null, msg);
    }

    // ---------------------------------------------------------------------
    // Flush (performs the DML)
    // ---------------------------------------------------------------------

    /**
     * Persists all buffered logs in a single insert. Call this AFTER all
     * callouts in the transaction have completed. A logging failure is swallowed
     * so it can never break business logic.
     */
    public static void flush() {
        if (buffer.isEmpty()) {
            return;
        }
        List<Apex_Log__c> toInsert = buffer;
        buffer = new List<Apex_Log__c>();
        try {
            insert toInsert;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'ApexLogUtil.flush failed to insert ' + toInsert.size()
                + ' log(s): ' + e.getMessage());
        }
    }

    /** Number of logs currently buffered (useful for tests / diagnostics). */
    public static Integer pending() {
        return buffer.size();
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private static String truncate(String value, Integer max) {
        if (value == null) {
            return null;
        }
        return value.length() > max ? value.substring(0, max) : value;
    }
}
