/// Core service traits and implementations for the application.
///
/// This module defines the service layer with trait-based abstractions
/// for dependency injection and testability.

mod service;

pub use service::{DataProcessor, FileProcessor, NetworkProcessor};

/// Represents a processing result with metadata.
#[derive(Debug)]
pub struct ProcessResult {
    pub success: bool,
    pub items_processed: usize,
    pub errors: Vec<String>,
}

impl ProcessResult {
    pub fn ok(items: usize) -> Self {
        Self {
            success: true,
            items_processed: items,
            errors: Vec::new(),
        }
    }

    pub fn with_errors(items: usize, errors: Vec<String>) -> Self {
        Self {
            success: errors.is_empty(),
            items_processed: items,
            errors,
        }
    }
}

impl std::fmt::Display for ProcessResult {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.success {
            write!(f, "OK: {} items processed", self.items_processed)
        } else {
            write!(
                f,
                "FAILED: {} items, {} errors",
                self.items_processed,
                self.errors.len()
            )
        }
    }
}

/// Configuration for data processing pipelines.
#[derive(Debug, Clone)]
pub struct PipelineConfig {
    pub max_retries: u32,
    pub timeout_ms: u64,
    pub batch_size: usize,
}

impl Default for PipelineConfig {
    fn default() -> Self {
        Self {
            max_retries: 3,
            timeout_ms: 5000,
            batch_size: 100,
        }
    }
}
