use crate::error::PipelineError;

/// A record stored or retrieved by a storage backend.
#[derive(Debug, Clone)]
pub struct Record {
    pub id: u64,
    pub key: String,
    pub value: Vec<u8>,
}

/// Trait for storage backends.
pub trait StorageBackend: Send + Sync {
    /// Store a record. Returns the assigned ID.
    fn put(&mut self, key: &str, value: &[u8]) -> Result<u64, PipelineError>;

    /// Retrieve a record by key.
    fn get(&self, key: &str) -> Result<Option<Record>, PipelineError>;

    /// Delete a record by key. Returns true if a record was removed.
    fn delete(&mut self, key: &str) -> Result<bool, PipelineError>;

    /// List all keys matching a prefix.
    fn list_keys(&self, prefix: &str) -> Result<Vec<String>, PipelineError>;
}

/// In-memory storage backend, useful for testing.
pub struct MemoryStorage {
    next_id: u64,
    records: std::collections::HashMap<String, Record>,
}

impl MemoryStorage {
    pub fn new() -> Self {
        Self {
            next_id: 1,
            records: std::collections::HashMap::new(),
        }
    }
}

impl StorageBackend for MemoryStorage {
    fn put(&mut self, key: &str, value: &[u8]) -> Result<u64, PipelineError> {
        let id = self.next_id;
        self.next_id += 1;
        self.records.insert(
            key.to_string(),
            Record {
                id,
                key: key.to_string(),
                value: value.to_vec(),
            },
        );
        Ok(id)
    }

    fn get(&self, key: &str) -> Result<Option<Record>, PipelineError> {
        Ok(self.records.get(key).cloned())
    }

    fn delete(&mut self, key: &str) -> Result<bool, PipelineError> {
        Ok(self.records.remove(key).is_some())
    }

    fn list_keys(&self, prefix: &str) -> Result<Vec<String>, PipelineError> {
        Ok(self
            .records
            .keys()
            .filter(|k| k.starts_with(prefix))
            .cloned()
            .collect())
    }
}

/// File-based storage backend.
pub struct FileStorage {
    base_dir: std::path::PathBuf,
    next_id: u64,
}

impl FileStorage {
    pub fn new(base_dir: std::path::PathBuf) -> Self {
        Self { base_dir, next_id: 1 }
    }

    fn key_path(&self, key: &str) -> std::path::PathBuf {
        self.base_dir.join(key)
    }
}

impl StorageBackend for FileStorage {
    fn put(&mut self, key: &str, value: &[u8]) -> Result<u64, PipelineError> {
        let path = self.key_path(key);
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(&path, value)?;
        let id = self.next_id;
        self.next_id += 1;
        Ok(id)
    }

    fn get(&self, key: &str) -> Result<Option<Record>, PipelineError> {
        let path = self.key_path(key);
        if path.exists() {
            let value = std::fs::read(&path)?;
            Ok(Some(Record {
                id: 0,
                key: key.to_string(),
                value,
            }))
        } else {
            Ok(None)
        }
    }

    fn delete(&mut self, key: &str) -> Result<bool, PipelineError> {
        let path = self.key_path(key);
        if path.exists() {
            std::fs::remove_file(&path)?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    fn list_keys(&self, prefix: &str) -> Result<Vec<String>, PipelineError> {
        let mut keys = Vec::new();
        if self.base_dir.exists() {
            for entry in std::fs::read_dir(&self.base_dir)? {
                let entry = entry?;
                let name = entry.file_name().to_string_lossy().to_string();
                if name.starts_with(prefix) {
                    keys.push(name);
                }
            }
        }
        Ok(keys)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn memory_storage_put_get() {
        let mut store = MemoryStorage::new();
        let id = store.put("key1", b"hello").unwrap();
        assert_eq!(id, 1);
        let record = store.get("key1").unwrap().unwrap();
        assert_eq!(record.value, b"hello");
    }

    #[test]
    fn memory_storage_delete() {
        let mut store = MemoryStorage::new();
        store.put("key1", b"hello").unwrap();
        assert!(store.delete("key1").unwrap());
        assert!(store.get("key1").unwrap().is_none());
    }
}
