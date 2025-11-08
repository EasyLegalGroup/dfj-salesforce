public interface DFJ_callhistoryArchiver {
    Database.SaveResult[] insertRecords(List<Telegenta_Call_History__b> records);
}