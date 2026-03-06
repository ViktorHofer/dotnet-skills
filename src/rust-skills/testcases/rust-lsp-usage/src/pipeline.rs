use crate::error::PipelineError;
use crate::processor::DataProcessor;
use crate::storage::StorageBackend;

/// Configuration for a processing pipeline.
pub struct PipelineConfig {
    pub input_prefix: String,
    pub output_prefix: String,
}

/// Orchestrates data flow: reads from storage, processes, writes back.
pub struct Pipeline<S: StorageBackend> {
    storage: S,
    processor: Box<dyn DataProcessor>,
    config: PipelineConfig,
}

impl<S: StorageBackend> Pipeline<S> {
    pub fn new(storage: S, processor: Box<dyn DataProcessor>, config: PipelineConfig) -> Self {
        Self {
            storage,
            processor,
            config,
        }
    }

    /// Run the pipeline on all keys matching the input prefix.
    pub fn run(&mut self) -> Result<PipelineStats, PipelineError> {
        let keys = self.storage.list_keys(&self.config.input_prefix)?;
        let mut stats = PipelineStats {
            keys_processed: 0,
            bytes_in: 0,
            bytes_out: 0,
            errors: Vec::new(),
        };

        for key in &keys {
            match self.process_key(key) {
                Ok((bytes_in, bytes_out)) => {
                    stats.keys_processed += 1;
                    stats.bytes_in += bytes_in;
                    stats.bytes_out += bytes_out;
                }
                Err(e) => {
                    stats.errors.push(format!("{key}: {e}"));
                }
            }
        }

        Ok(stats)
    }

    fn process_key(&mut self, key: &str) -> Result<(usize, usize), PipelineError> {
        let record = self
            .storage
            .get(key)?
            .ok_or_else(|| PipelineError::Storage(format!("key not found: {key}")))?;

        let bytes_in = record.value.len();
        let output = self.processor.process(&record.value)?;
        let bytes_out = output.len();

        let output_key = key.replacen(
            &self.config.input_prefix,
            &self.config.output_prefix,
            1,
        );
        self.storage.put(&output_key, &output)?;

        Ok((bytes_in, bytes_out))
    }

    /// Access the underlying storage (for inspection/testing).
    pub fn storage(&self) -> &S {
        &self.storage
    }
}

/// Statistics returned after a pipeline run.
#[derive(Debug)]
pub struct PipelineStats {
    pub keys_processed: usize,
    pub bytes_in: usize,
    pub bytes_out: usize,
    pub errors: Vec<String>,
}

impl std::fmt::Display for PipelineStats {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Processed {} keys ({} bytes in, {} bytes out, {} errors)",
            self.keys_processed,
            self.bytes_in,
            self.bytes_out,
            self.errors.len()
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::processor::UppercaseProcessor;
    use crate::storage::MemoryStorage;

    #[test]
    fn pipeline_processes_matching_keys() {
        let mut storage = MemoryStorage::new();
        storage.put("input/a.txt", b"hello").unwrap();
        storage.put("input/b.txt", b"world").unwrap();
        storage.put("other/c.txt", b"skip me").unwrap();

        let config = PipelineConfig {
            input_prefix: "input/".to_string(),
            output_prefix: "output/".to_string(),
        };

        let mut pipeline = Pipeline::new(
            storage,
            Box::new(UppercaseProcessor),
            config,
        );

        let stats = pipeline.run().unwrap();
        assert_eq!(stats.keys_processed, 2);

        let result = pipeline.storage().get("output/a.txt").unwrap().unwrap();
        assert_eq!(result.value, b"HELLO");
    }
}
