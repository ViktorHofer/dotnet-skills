use crate::{PipelineConfig, ProcessResult};

/// Trait for data processing services.
///
/// Implementations handle different data sources (files, network, databases)
/// with a unified processing interface.
pub trait DataProcessor {
    /// Process a batch of items and return the result.
    fn process(&self, items: &[String]) -> ProcessResult;

    /// Return the name of this processor for logging.
    fn name(&self) -> &str;

    /// Check if this processor is healthy and ready.
    fn health_check(&self) -> bool;
}

/// Processes data from local files.
pub struct FileProcessor {
    config: PipelineConfig,
    base_path: String,
}

impl FileProcessor {
    pub fn new(base_path: &str, config: PipelineConfig) -> Self {
        Self {
            config,
            base_path: base_path.to_string(),
        }
    }

    fn validate_path(&self, path: &str) -> bool {
        path.starts_with(&self.base_path) && !path.contains("..")
    }
}

impl DataProcessor for FileProcessor {
    fn process(&self, items: &[String]) -> ProcessResult {
        let mut errors = Vec::new();
        let mut processed = 0;

        for (i, item) in items.iter().enumerate() {
            if !self.validate_path(item) {
                errors.push(format!("Invalid path at index {}: {}", i, item));
                continue;
            }
            if processed >= self.config.batch_size {
                break;
            }
            processed += 1;
        }

        ProcessResult::with_errors(processed, errors)
    }

    fn name(&self) -> &str {
        "FileProcessor"
    }

    fn health_check(&self) -> bool {
        std::path::Path::new(&self.base_path).exists()
    }
}

/// Processes data from network endpoints.
pub struct NetworkProcessor {
    config: PipelineConfig,
    endpoint: String,
}

impl NetworkProcessor {
    pub fn new(endpoint: &str, config: PipelineConfig) -> Self {
        Self {
            config,
            endpoint: endpoint.to_string(),
        }
    }
}

impl DataProcessor for NetworkProcessor {
    fn process(&self, items: &[String]) -> ProcessResult {
        let batch_count = items.len().min(self.config.batch_size);
        // Simulate network processing with retry logic
        let mut attempt = 0;
        while attempt < self.config.max_retries {
            attempt += 1;
            // In real code, this would make HTTP requests
            if attempt > 1 {
                break; // Simulate success on retry
            }
        }
        ProcessResult::ok(batch_count)
    }

    fn name(&self) -> &str {
        "NetworkProcessor"
    }

    fn health_check(&self) -> bool {
        !self.endpoint.is_empty()
    }
}

/// Runs all processors in sequence and collects results.
pub fn run_pipeline(processors: &[&dyn DataProcessor], data: &[String]) -> Vec<ProcessResult> {
    processors
        .iter()
        .filter(|p| p.health_check())
        .map(|p| {
            let result = p.process(data);
            println!("[{}] {}", p.name(), result);
            result
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_file_processor_valid_paths() {
        let config = PipelineConfig::default();
        let proc = FileProcessor::new("/tmp", config);
        let items = vec!["/tmp/file1.txt".to_string(), "/tmp/file2.txt".to_string()];
        let result = proc.process(&items);
        assert!(result.success);
        assert_eq!(result.items_processed, 2);
    }

    #[test]
    fn test_network_processor() {
        let config = PipelineConfig::default();
        let proc = NetworkProcessor::new("https://api.example.com", config);
        assert!(proc.health_check());
        let result = proc.process(&vec!["item1".to_string()]);
        assert!(result.success);
    }

    #[test]
    fn test_pipeline_execution() {
        let config = PipelineConfig::default();
        let file_proc = FileProcessor::new("/tmp", config.clone());
        let net_proc = NetworkProcessor::new("https://api.example.com", config);
        let processors: Vec<&dyn DataProcessor> = vec![&file_proc, &net_proc];
        let data = vec!["item1".to_string()];
        let results = run_pipeline(&processors, &data);
        assert_eq!(results.len(), 2);
    }
}
