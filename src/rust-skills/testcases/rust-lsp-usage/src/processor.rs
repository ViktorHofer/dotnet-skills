use crate::error::PipelineError;

/// Trait for data processors that transform byte data.
pub trait DataProcessor: Send + Sync {
    /// The name of this processor (for logging).
    fn name(&self) -> &str;

    /// Process the input bytes, returning transformed output.
    fn process(&self, input: &[u8]) -> Result<Vec<u8>, PipelineError>;
}

/// Converts all ASCII bytes to uppercase.
pub struct UppercaseProcessor;

impl DataProcessor for UppercaseProcessor {
    fn name(&self) -> &str {
        "uppercase"
    }

    fn process(&self, input: &[u8]) -> Result<Vec<u8>, PipelineError> {
        Ok(input.iter().map(|b| b.to_ascii_uppercase()).collect())
    }
}

/// Compresses data by run-length encoding repeated bytes.
pub struct RleProcessor;

impl DataProcessor for RleProcessor {
    fn name(&self) -> &str {
        "rle-compress"
    }

    fn process(&self, input: &[u8]) -> Result<Vec<u8>, PipelineError> {
        if input.is_empty() {
            return Ok(Vec::new());
        }

        let mut output = Vec::new();
        let mut current = input[0];
        let mut count: u8 = 1;

        for &byte in &input[1..] {
            if byte == current && count < 255 {
                count += 1;
            } else {
                output.push(count);
                output.push(current);
                current = byte;
                count = 1;
            }
        }
        output.push(count);
        output.push(current);

        Ok(output)
    }
}

/// Validates that input is valid UTF-8 text.
pub struct Utf8Validator;

impl DataProcessor for Utf8Validator {
    fn name(&self) -> &str {
        "utf8-validate"
    }

    fn process(&self, input: &[u8]) -> Result<Vec<u8>, PipelineError> {
        std::str::from_utf8(input)
            .map_err(|e| PipelineError::InvalidInput(format!("invalid UTF-8: {e}")))?;
        Ok(input.to_vec())
    }
}

/// Chains multiple processors together.
pub struct ProcessorChain {
    processors: Vec<Box<dyn DataProcessor>>,
}

impl ProcessorChain {
    pub fn new() -> Self {
        Self {
            processors: Vec::new(),
        }
    }

    pub fn add(mut self, processor: Box<dyn DataProcessor>) -> Self {
        self.processors.push(processor);
        self
    }

    pub fn processors(&self) -> &[Box<dyn DataProcessor>] {
        &self.processors
    }
}

impl DataProcessor for ProcessorChain {
    fn name(&self) -> &str {
        "chain"
    }

    fn process(&self, input: &[u8]) -> Result<Vec<u8>, PipelineError> {
        let mut data = input.to_vec();
        for proc in &self.processors {
            data = proc.process(&data).map_err(|e| PipelineError::Processing {
                step: proc.name().to_string(),
                reason: e.to_string(),
            })?;
        }
        Ok(data)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uppercase_processor() {
        let proc = UppercaseProcessor;
        let result = proc.process(b"hello world").unwrap();
        assert_eq!(result, b"HELLO WORLD");
    }

    #[test]
    fn chain_processors() {
        let chain = ProcessorChain::new()
            .add(Box::new(Utf8Validator))
            .add(Box::new(UppercaseProcessor));
        let result = chain.process(b"hello").unwrap();
        assert_eq!(result, b"HELLO");
    }
}
