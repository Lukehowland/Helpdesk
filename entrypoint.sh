#!/bin/bash
set -e

echo "🚀 Starting Helpdesk container..."

# ------------------------------------------------------------------------------
# Wait for PostgreSQL
# ------------------------------------------------------------------------------
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -U "$DB_USERNAME" > /dev/null 2>&1; do
    echo "   PostgreSQL is unavailable - sleeping"
    sleep 2
done
echo "✅ PostgreSQL is ready!"
sleep 3

# ------------------------------------------------------------------------------
# Composer install (SAFE MODE - NO ZIP)
# ------------------------------------------------------------------------------
if [ ! -d "vendor/laravel/framework" ]; then
    echo "📦 Installing Composer dependencies (safe mode)..."

    rm -rf vendor

    composer install \
        --no-interaction \
        --no-progress \
        --prefer-source \
        --optimize-autoloader
fi

# ------------------------------------------------------------------------------
# Storage permissions
# ------------------------------------------------------------------------------
echo "📁 Setting up storage permissions..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# ------------------------------------------------------------------------------
# Generate APP_KEY if missing
# ------------------------------------------------------------------------------
if [ ! -f .env ] || grep -q "^APP_KEY=$" .env; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# ------------------------------------------------------------------------------
# Migrations
# ------------------------------------------------------------------------------
echo "🗄️ Running migrations..."
php artisan migrate --force

# ------------------------------------------------------------------------------
# Seed database (non-blocking)
# ------------------------------------------------------------------------------
echo "🌱 Seeding database..."
php artisan db:seed --class='Database\\Seeders\\DatabaseSeeder' --force || true

# ------------------------------------------------------------------------------
# Optimize Laravel
# ------------------------------------------------------------------------------
echo "🧹 Optimizing application..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan config:cache
php artisan route:cache

# ------------------------------------------------------------------------------
# Storage link
# ------------------------------------------------------------------------------
if [ ! -L "public/storage" ]; then
    echo "🔗 Creating storage link..."
    php artisan storage:link
fi

echo "✅ Helpdesk ready!"

# ------------------------------------------------------------------------------
# Start PHP-FPM
# ------------------------------------------------------------------------------
exec php-fpm
