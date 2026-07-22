<?php

class UploadController {

    public function uploadImage(): void {
        $userId = AuthMiddleware::getUserId();

        if (!isset($_FILES['file'])) {
            Response::error('No file uploaded', 400);
            exit;
        }

        $file = $_FILES['file'];
        $errors = self::validateFile($file, AppConfig::ALLOWED_IMAGE_TYPES, 5 * 1024 * 1024);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $result = self::storeFile($file, AppConfig::UPLOAD_DIR_IMAGES, 'image');

        Response::created([
            'url' => $result['url'],
            'filename' => $result['filename'],
            'size' => $result['size'],
            'mime_type' => $result['mime_type'],
        ], 'Image uploaded successfully');
    }

    public function uploadAttachment(): void {
        $userId = AuthMiddleware::getUserId();

        if (!isset($_FILES['file'])) {
            Response::error('No file uploaded', 400);
            exit;
        }

        $file = $_FILES['file'];
        $allowedTypes = array_merge(AppConfig::ALLOWED_IMAGE_TYPES, AppConfig::ALLOWED_ATTACHMENT_TYPES);
        $errors = self::validateFile($file, $allowedTypes, AppConfig::UPLOAD_MAX_SIZE);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $result = self::storeFile($file, AppConfig::UPLOAD_DIR_ATTACHMENTS, 'attachment');

        Response::created([
            'url' => $result['url'],
            'filename' => $result['filename'],
            'original_name' => $result['original_name'],
            'size' => $result['size'],
            'mime_type' => $result['mime_type'],
        ], 'Attachment uploaded successfully');
    }

    private static function validateFile(array $file, array $allowedTypes, int $maxSize): array {
        $errors = [];

        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errorMessages = [
                UPLOAD_ERR_INI_SIZE => 'File exceeds server upload limit',
                UPLOAD_ERR_FORM_SIZE => 'File exceeds form upload limit',
                UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
                UPLOAD_ERR_NO_FILE => 'No file was uploaded',
                UPLOAD_ERR_NO_TMP_DIR => 'Server missing temporary folder',
                UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
                UPLOAD_ERR_EXTENSION => 'Upload stopped by extension',
            ];
            $errors[] = $errorMessages[$file['error']] ?? 'Unknown upload error';
            return $errors;
        }

        if ($file['size'] > $maxSize) {
            $maxMb = round($maxSize / (1024 * 1024), 1);
            $errors[] = "File size exceeds {$maxMb}MB limit";
        }

        if ($file['size'] === 0) {
            $errors[] = 'File is empty';
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->file($file['tmp_name']);

        if (!in_array($mimeType, $allowedTypes)) {
            $errors[] = "File type '{$mimeType}' is not allowed";
        }

        $filename = strtolower(basename($file['name']));
        $extension = pathinfo($filename, PATHINFO_EXTENSION);
        $dangerousExtensions = ['php', 'php3', 'php4', 'php5', 'php7', 'php8', 'phtml', 'pht', 'phps', 'cgi', 'pl', 'asp', 'aspx', 'jsp', 'sh', 'bash', 'exe', 'bat', 'cmd', 'com', 'msi', 'scr', 'vbs', 'js', 'reg'];

        if (in_array($extension, $dangerousExtensions)) {
            $errors[] = 'File type not allowed for security reasons';
        }

        return $errors;
    }

    private static function storeFile(array $file, string $uploadDir, string $type): array {
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->file($file['tmp_name']);

        $extension = self::getExtensionFromMime($mimeType);
        if (!$extension) {
            $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
        }

        $dateDir = date('Y/m');
        $fullDir = $uploadDir . $dateDir;
        if (!is_dir($fullDir)) {
            mkdir($fullDir, 0755, true);
        }

        $filename = bin2hex(random_bytes(16)) . '.' . $extension;
        $destination = $fullDir . '/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $destination)) {
            Logger::error("Failed to move uploaded file", ['tmp' => $file['tmp_name'], 'dest' => $destination]);
            throw new RuntimeException('Failed to save uploaded file');
        }

        chmod($destination, 0644);

        $relativePath = 'uploads/' . $type . '/' . $dateDir . '/' . $filename;

        return [
            'url' => '/' . $relativePath,
            'filename' => $filename,
            'original_name' => $file['name'],
            'size' => $file['size'],
            'mime_type' => $mimeType,
            'path' => $relativePath,
        ];
    }

    private static function getExtensionFromMime(string $mimeType): ?string {
        $map = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/gif' => 'gif',
            'image/webp' => 'webp',
            'application/pdf' => 'pdf',
            'application/msword' => 'doc',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
            'application/vnd.ms-excel' => 'xls',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'xlsx',
            'text/csv' => 'csv',
        ];

        return $map[$mimeType] ?? null;
    }
}
