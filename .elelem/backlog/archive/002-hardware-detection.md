As a `new user`, I `want elelem to detect my hardware capabilities`, so that `it can recommend an appropriate model for my system`.

# SYNOPSIS

Detect GPU/CPU capabilities to determine what models can run locally.

# DESCRIPTION

When elelem starts with no configuration, it should be able to detect:

1. **GPU presence and type**:
   - NVIDIA GPU with CUDA support (check nvidia-smi or similar)
   - AMD GPU with ROCm support
   - No discrete GPU (CPU-only fallback)

2. **Available VRAM/RAM**:
   - GPU memory available for model loading
   - System RAM as fallback for CPU inference

3. **Model recommendations**:
   - Map hardware capabilities to appropriate model sizes
   - Example: 8GB VRAM → 7B parameter model, 4GB VRAM → 3B model, CPU-only → small model

This information will be used by the local provider to:
- Select the default model automatically
- Warn users if their hardware may struggle with a requested model

# SEE ALSO

* [ ] lib/elelem/system_prompt.rb (platform detection)
* [ ] Story 001 (spike findings will inform implementation)

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] Correctly detects NVIDIA GPU presence on Linux
* [ ] Correctly detects AMD GPU presence on Linux  
* [ ] Correctly detects available VRAM when GPU present
* [ ] Correctly detects available system RAM
* [ ] Returns a capability summary that can be used for model selection
* [ ] Works gracefully when detection tools (nvidia-smi, rocm-smi) are not installed
