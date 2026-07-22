<?php

class CORSMiddleware {
    public static function handle(): void {
        CORSConfig::setHeaders();
    }
}
