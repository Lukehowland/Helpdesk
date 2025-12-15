#!/bin/bash
set -e

echo "🚀 Starting Helpdesk container..."

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h "$DB_HOST" -U "$DB_USERNAME" > /dev/null 2>&1; do
    echo "   PostgreSQL is unavailable - sleeping"
    sleep 2
done
echo "✅ PostgreSQL is ready!"
sleep 3

# Install Composer dependencies if not present
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Installing Composer dependencies..."
    composer install --prefer-dist --no-dev --no-interaction --optimize-autoloader
fi

# Setup storage permissions
echo "📁 Setting up storage permissions..."
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Generate APP_KEY if not set
if grep -q "APP_KEY=$" .env 2>/dev/null || [ ! -f .env ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Run migrations
echo "🗄️ Running migrations..."
php artisan migrate --force

# Seed database
echo "🌱 Seeding database..."
php artisan db:seed --class='Database\Seeders\DatabaseSeeder' --force || true

# Clear and optimize
echo "🧹 Optimizing..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear
php artisan config:cache
php artisan route:cache

# Storage link
if [ ! -L "public/storage" ]; then
    echo "🔗 Creating storage link..."
    php artisan storage:link
fi

echo "✅ Helpdesk ready!"

# Execute main command
exec php-fpm
