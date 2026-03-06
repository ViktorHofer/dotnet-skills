use std::fmt;

/// Errors that can occur during pipeline processing.
#[derive(Debug)]
pub enum PipelineError {
    /// Storage backend failed.
    Storage(String),
    /// A processing step failed.
    Processing { step: String, reason: String },
    /// The input data was invalid.
    InvalidInput(String),
    /// An I/O error occurred.
    Io(std::io::Error),
}

impl fmt::Display for PipelineError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Storage(msg) => write!(f, "storage error: {msg}"),
            Self::Processing { step, reason } => {
                write!(f, "processing error in '{step}': {reason}")
            }
            Self::InvalidInput(msg) => write!(f, "invalid input: {msg}"),
            Self::Io(err) => write!(f, "I/O error: {err}"),
        }
    }
}

impl std::error::Error for PipelineError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(err) => Some(err),
            _ => None,
        }
    }
}

impl From<std::io::Error> for PipelineError {
    fn from(err: std::io::Error) -> Self {
        Self::Io(err)
    }
}
