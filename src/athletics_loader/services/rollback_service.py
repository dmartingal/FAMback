class RollbackService:
    def plan(self, source_file_id: int) -> dict:
        return {"source_file_id": source_file_id, "status": "planned"}
