@echo off

REM ============================================
REM EC2 Democratic Shutdown - AWS Debug Test
REM Tests AWS CLI installation and connectivity
REM ============================================

echo === EC2 Democratic Shutdown - AWS Debug Test ===
echo.

echo [1/3] Testing AWS CLI installation...
aws --version
if errorlevel 1 (
    echo ERROR: AWS CLI not installed or not in PATH
    echo.
    echo Installation steps:
    echo 1. Download from: https://aws.amazon.com/cli/
    echo 2. Run the installer as administrator
    echo 3. Restart Command Prompt
    pause
    exit /b 1
)

echo.
echo [2/3] Testing AWS credentials...
aws sts get-caller-identity
if errorlevel 1 (
    echo ERROR: AWS credentials not configured
    echo.
    echo Configuration steps:
    echo 1. Run: aws configure
    echo 2. Enter your AWS Access Key ID
    echo 3. Enter your AWS Secret Access Key
    echo 4. Enter default region (e.g., us-west-2)
    echo 5. Enter default output format (json)
    echo.
    echo Get credentials from AWS Console:
    echo Your Name (top right) → Security Credentials → Access Keys
    pause
    exit /b 1
)

echo.
echo [3/3] Testing EC2 access...
if not exist config.bat (
    echo ERROR: config.bat not found!
    echo Cannot test EC2 instance access without configuration
    pause
    exit /b 1
)

call config.bat
echo Testing access to instance: %INSTANCE_ID%

aws ec2 describe-instances --region %AWS_REGION% --instance-ids %INSTANCE_ID% --output table
if errorlevel 1 (
    echo ERROR: Cannot access EC2 instance
    echo.
    echo Please verify in config.bat:
    echo - Instance ID: %INSTANCE_ID%
    echo - AWS Region: %AWS_REGION%
    echo.
    echo Also check:
    echo - Your AWS user has EC2 permissions
    echo - Instance exists in the specified region
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ SUCCESS: All AWS commands working!
echo ========================================
echo.
echo Your configuration status:
echo - AWS CLI: ✓ Installed and working
echo - Credentials: ✓ Valid and configured  
echo - EC2 Access: ✓ Can access your instance
echo - Instance ID: %INSTANCE_ID%
echo - Region: %AWS_REGION%
echo.
echo 🎉 You're ready to use the EC2 Democratic Shutdown System!
echo.
echo Next steps:
echo 1. Run: start_server.bat (to start your server)
echo 2. Run: view_config.bat (to see full configuration)
echo 3. Run: shutdown_server.bat (to test democratic shutdown)
echo.
pause