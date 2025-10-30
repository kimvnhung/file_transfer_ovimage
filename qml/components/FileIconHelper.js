// File icon and formatting utilities
// .pragma library

function getFileIcon(fileName) {
    var ext = fileName.split('.').pop().toLowerCase()
    
    // Images
    if (["jpg", "jpeg", "png", "gif", "bmp", "svg"].includes(ext)) return "🖼️"
    
    // Documents
    if (["pdf", "doc", "docx", "txt", "rtf", "odt"].includes(ext)) return "📄"
    
    // Archives
    if (["zip", "rar", "7z", "tar", "gz"].includes(ext)) return "📦"
    
    // Videos
    if (["mp4", "avi", "mkv", "mov", "wmv"].includes(ext)) return "🎥"
    
    // Audio
    if (["mp3", "wav", "flac", "ogg", "m4a"].includes(ext)) return "🎵"
    
    // Code
    if (["js", "py", "cpp", "h", "java", "cs", "php", "qml"].includes(ext)) return "💻"
    
    return "📄"
}

function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
    return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB"
}
