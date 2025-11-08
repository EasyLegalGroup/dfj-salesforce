public interface DFJ_EmailMessageArchiver {
    Database.SaveResult[] insertRecords(List<Email_Message__b> records);
}