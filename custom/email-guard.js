var https = require('https');

function checkEmail(email) {
    return new Promise(function(resolve) {
        var url = 'https://rapid-email-verifier.fly.dev/api/validate?email=' + encodeURIComponent(email);
        https.get(url, { timeout: 5000 }, function(res) {
            var body = '';
            res.on('data', function(c) { body += c; });
            res.on('end', function() {
                try {
                    var data = JSON.parse(body);
                    if (data.disposable === true || data.is_disposable === true || data.temporary === true) {
                        console.log('[EMAIL-GUARD] Blocked disposable email: ' + email);
                        resolve({ valid: false, reason: 'Temporary email addresses are not allowed. Please use a permanent email.' });
                    } else {
                        resolve({ valid: true });
                    }
                } catch(e) {
                    resolve({ valid: true }); // Allow on parse error
                }
            });
        }).on('error', function() {
            resolve({ valid: true }); // Allow on network error
        });
    });
}

module.exports = { checkEmail: checkEmail };
