<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Migración para mover las tablas company_announcements y service_api_keys
 * al schema 'business' de PostgreSQL.
 * 
 * Esta migración usa ALTER TABLE ... SET SCHEMA que es una operación atómica
 * y preserva automáticamente:
 * - Datos existentes
 * - Foreign keys
 * - Índices
 * - Constraints
 * 
 * @see https://www.postgresql.org/docs/current/sql-altertable.html
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Mover company_announcements al schema business
        DB::statement('ALTER TABLE public.company_announcements SET SCHEMA business');
        
        // Mover service_api_keys al schema business
        DB::statement('ALTER TABLE public.service_api_keys SET SCHEMA business');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revertir: mover de vuelta al schema public
        DB::statement('ALTER TABLE business.company_announcements SET SCHEMA public');
        DB::statement('ALTER TABLE business.service_api_keys SET SCHEMA public');
    }
};
