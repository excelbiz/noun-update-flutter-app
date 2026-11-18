<?php
session_start();

// Ensure the cart exists
if (!isset($_SESSION['cart'])) {
    $_SESSION['cart'] = array();
}

// connect to database
require_once __DIR__ . '/nu-mobile/bootstrap.php';
$nuContent = $nuConfig['content_db'];
$con = mysqli_connect($nuContent['host'], $nuContent['user'], $nuContent['pass'], $nuContent['name']);
mysqli_set_charset($con, 'utf8mb4');

// check connection
if (mysqli_connect_errno()) {
    echo "The cart is temporarily unavailable. Please try again shortly.";
    exit();
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (isset($_POST['action']) && $_POST['action'] == 'remove') {
        $file_id = isset($_POST['file_id']) ? intval($_POST['file_id']) : 0;
        if ($file_id > 0) {
            // Function to remove item from cart
            function removeFromCart($file_id) {
                $key = array_search($file_id, $_SESSION['cart']);
                if ($key !== false) {
                    unset($_SESSION['cart'][$key]);
                    $_SESSION['cart'] = array_values($_SESSION['cart']); // Re-index the array
                }
            }

            removeFromCart($file_id);
        }
    } elseif (isset($_POST['action']) && $_POST['action'] == 'checkout') {
        // Collect customer information
        $email = isset($_POST['email']) ? mysqli_real_escape_string($con, $_POST['email']) : '';
        $whatsapp_number = isset($_POST['whatsapp_number']) ? mysqli_real_escape_string($con, $_POST['whatsapp_number']) : '';
        $surname = isset($_POST['surname']) ? mysqli_real_escape_string($con, $_POST['surname']) : '';
        $other_names = isset($_POST['other_names']) ? mysqli_real_escape_string($con, $_POST['other_names']) : '';

        // Store customer information in session
        $_SESSION['customer_info'] = array(
            'email' => $email,
            'whatsapp_number' => $whatsapp_number,
            'surname' => $surname,
            'other_names' => $other_names
        );

        // Redirect to Paystack
        header("Location: paystack.php");
        exit();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Summaries Cart</title>
    <!-- Add Bootstrap CSS -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" integrity="sha512-9usAa10IRO0HhonpyAIVpjrylPvoDwiPUiKdWk5t3PyolY1cOd4DSE0Ga+ri4AuTroPR5aQvXU9xC6qOPnzFeg==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <style>
        :root{
            --primary:#10b981; /* Emerald Green */
            --primary-dark:#047857; /* Darker Emerald */
            --primary-light:#ecfdf5; /* Mint Light Background */
            --secondary:#059669; /* Medium Emerald */
            --dark:#0f172a;
            --text:#475569;
            --muted:#64748b;
            --white:#ffffff;
            --border:#e2e8f0;
            --bg:#f8fafc;
            --danger:#ef4444;
            --warning:#f59e0b;
            --radius:24px;
            --shadow:0 15px 40px rgba(15,23,42,0.06);
            --transition:0.3s ease;
        }

        body {
            background: linear-gradient(to bottom, var(--primary-light), #ffffff);
            font-family: 'Inter', sans-serif;
            color: var(--text);
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        .container {
            max-width: 800px;
            margin: 40px auto;
            padding: 40px 30px;
            background-color: var(--white);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            border: 1px solid rgba(226, 232, 240, 0.7);
            flex: 1; /* Allow container to grow and take available space */
        }

        h1 {
            text-align: center;
            color: var(--dark);
            font-weight: 800;
            font-size: 2.2rem;
            margin-bottom: 30px;
        }

        .table {
            background-color: var(--white);
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid var(--border);
            margin-bottom: 30px;
        }

        .table thead th {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
            border: none;
            text-align: center;
            font-weight: 700;
            padding: 16px;
        }

        .table tbody td {
            border-bottom: 1px solid var(--border);
            text-align: center;
            padding: 16px;
            color: var(--dark);
            font-weight: 500;
            vertical-align: middle;
        }

        .table tfoot th {
            border: none;
            padding: 16px;
            font-size: 1.1rem;
            color: var(--dark);
            font-weight: 800;
        }

        .btn-danger {
            background-color: var(--danger);
            border: none;
            border-radius: 12px;
            padding: 8px 16px;
            font-weight: 700;
            transition: var(--transition);
        }

        .btn-danger:hover {
            background-color: #dc2626;
            transform: translateY(-1px);
        }

        .form-group {
            margin-bottom: 24px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: var(--muted);
            text-transform: uppercase;
            margin-bottom: 8px;
            letter-spacing: 0.5px;
        }

        .form-control {
            width: 100%;
            border: 1px solid var(--border);
            background: #f8fafc;
            padding: 16px 20px;
            border-radius: 16px;
            font-size: 15px;
            color: var(--dark);
            transition: var(--transition);
            outline: none;
            height: auto;
        }

        .form-control:focus {
            border-color: var(--primary);
            background: white;
            box-shadow: 0 0 0 4px var(--primary-light);
            color: var(--dark);
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
            border: none;
            color: white;
            padding: 16px 24px;
            font-weight: 700;
            border-radius: 18px;
            transition: var(--transition);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            width: 100%;
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.2);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(16, 185, 129, 0.3);
            background: linear-gradient(135deg, var(--primary), var(--primary-dark));
        }

        /* Floating Cart Button */
        .cart-button {
            position: fixed; /* Make it float */
            top: 20px;       /* Adjust as needed */
            right: 20px;     /* Adjust as needed */
            padding: 12px;
            border-radius: 50%;
            background-color: var(--white);
            box-shadow: var(--shadow);
            border: 1px solid var(--border);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 52px;
            height: 52px;
            z-index: 100; /* Ensure it's on top */
            transition: var(--transition);
        }

        .cart-button:hover {
            transform: translateY(-2px);
        }

        .cart-icon {
            font-size: 20px;
            color: var(--primary);
        }

        .cart-count {
            position: absolute;
            top: -5px;
            right: -5px;
            background-color: var(--danger);
            color: white;
            border-radius: 50%;
            padding: 4px 8px;
            font-size: 12px;
            font-weight: 700;
        }

        .back-to-shop {
            margin-top: 30px;
            text-align: center;
        }

        .back-to-shop a {
            color: var(--primary);
            font-weight: 700;
            transition: var(--transition);
        }

        .back-to-shop a:hover {
            color: var(--primary-dark);
            text-decoration: none;
        }

        /* Styles for mobile bottom navigation */
        .mobile-bottom-nav {
            position: fixed;
            bottom: 0;
            left: 0;
            width: 100%;
            background-color: rgba(255, 255, 255, 0.92);
            backdrop-filter: blur(14px);
            border-top: 1px solid rgba(226, 232, 240, 0.8);
            box-shadow: 0 -3px 12px rgba(0, 0, 0, 0.05);
            display: flex;
            justify-content: space-around;
            align-items: center;
            padding: 12px 0;
            z-index: 100; /* Ensure it's on top */
        }

        .mobile-bottom-nav a {
            color: var(--primary);
            text-decoration: none;
            display: flex;
            flex-direction: column;
            align-items: center;
            font-weight: 600;
            font-size: 12px;
        }

        .mobile-bottom-nav i {
            font-size: 20px;
            margin-bottom: 5px;
        }

        .mobile-bottom-nav a:hover {
            color: var(--primary-dark);
            text-decoration: none;
        }

        /* Hide on larger screens */
        @media (min-width: 769px) {
            .mobile-bottom-nav {
                display: none;
            }
        }

        /* Mobile Responsive */
        @media (max-width: 768px) {
            .container {
                padding: 30px 16px;
                margin: 20px auto 80px;
            }

            h1 {
                font-size: 1.8rem;
            }

            .table thead th, .table tbody td {
                font-size: 14px;
                padding: 12px 8px;
            }

            .form-control {
                padding: 12px 16px;
            }

            .btn {
                padding: 12px 20px;
            }

            /* Move cart button to top right */
            .cart-button {
                position: fixed;
                top: 15px;
                right: 15px;
                width: 44px;
                height: 44px;
            }

            .cart-icon {
                font-size: 16px;
            }

            .cart-count {
                font-size: 10px;
                padding: 2px 6px;
            }
        }

        /* Notification Styling */
        .mobile-bottom-nav a {
            position: relative;  /* Needs a position attribute */
        }

        .notification-count {
            position: absolute;
            top: -5px;
            right: -5px;
            background-color: var(--danger);
            color: white;
            border-radius: 50%;
            padding: 2px 6px;
            font-size: 10px;
            font-weight: bold;
            z-index: 2; /* Ensure it's above the icon */
        }

        .custom-popup ul {
            list-style-type: disc; /* Adds bullet points */
            padding-left: 20px;   /* Indent the list */
            text-align: left;      /* Align text to the left */
        }

        .custom-popup li {
            margin-bottom: 12px;    /* Spacing between list items */
        }

        /* Popup Styles */
        .custom-popup {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: rgba(255, 255, 255, 0.95); /* Glassmorphism effect */
            backdrop-filter: blur(10px); /* Frosted glass effect */
            border-radius: 20px;
            box-shadow: 0 10px 40px rgba(15, 23, 42, 0.1);
            border: 1px solid var(--border);
            padding: 30px;
            text-align: center;
            z-index: 1000;
            max-width: 90%;
            width: 500px; /* Adjust as needed */
            max-height: 80vh; /* Set maximum height */
            overflow-y: auto; /* Enable scroll if content overflows */
            opacity: 0;
            visibility: hidden;
            transition: opacity 0.3s, visibility 0.3s, transform 0.3s;
            transform: translate(-50%, -50%) scale(0.8);
        }

        .custom-popup.show {
            opacity: 1;
            visibility: visible;
            transform: translate(-50%, -50%) scale(1);
        }

        .custom-popup .popup-icon {
            font-size: 72px;
            color: var(--primary);
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.05);
        }

        .custom-popup h2 {
            color: var(--dark);
            margin-bottom: 20px;
            font-size: 24px;
            font-weight: 800;
        }

        .custom-popup p {
            color: var(--text);
            line-height: 1.7;
            margin-bottom: 30px;
            font-size: 15px;
        }

        .custom-popup .close-button {
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 12px 28px;
            border-radius: 30px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 700;
            transition: var(--transition);
            box-shadow: 0 4px 12px rgba(16, 185, 129, 0.2);
        }

        .custom-popup .close-button:hover {
            background-color: var(--primary-dark);
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(16, 185, 129, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="cart-button" onclick="location.href='cart.php'">
            <i class="fas fa-shopping-cart cart-icon"></i>
            <span class="cart-count"><?php echo count($_SESSION['cart']); ?></span>
        </div>
        <h1>Summaries Cart</h1>
        <?php if (empty($_SESSION['cart'])): ?>
            <p class="text-center" style="padding: 40px 0; color: var(--muted); font-size: 1.1rem; font-weight: 500;">Your cart is empty.</p>
        <?php else: ?>
            <table class="table">
                <thead>
                    <tr>
                        <th>Item</th>
                        <th>Price</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php
                    $total = 0;
                    foreach ($_SESSION['cart'] as $file_id):
                        $sql = "SELECT * FROM files WHERE id = " . intval($file_id);
                        $result = mysqli_query($con, $sql);
                        if ($result && $file = mysqli_fetch_assoc($result)):
                            $total += $file['price'];
                            ?>
                            <tr>
                                <td><?php echo htmlspecialchars($file['name']); ?></td>
                                <td>₦<?php echo number_format($file['price'], 2); ?></td>
                                <td>
                                    <form method="post" action="cart.php">
                                        <input type="hidden" name="file_id" value="<?php echo $file['id']; ?>">
                                        <input type="hidden" name="action" value="remove">
                                        <button type="submit" class="btn btn-danger btn-sm">Remove</button>
                                    </form>
                                </td>
                            </tr>
                            <?php
                        endif;
                    endforeach;
                    ?>
                </tbody>
                <tfoot>
                    <tr>
                        <th>Total</th>
                        <th>₦<?php echo number_format($total, 2); ?></th>
                        <th></th>
                    </tr>
                </tfoot>
            </table>

            <!-- Customer Information Form -->
            <form method="post" action="cart.php">
                <div class="form-group">
                    <label for="surname">Surname</label>
                    <input type="text" class="form-control" id="surname" name="surname" placeholder="e.g. Cole" required>
                </div>
                <div class="form-group">
                    <label for="other_names">Other Names</label>
                    <input type="text" class="form-control" id="other_names" name="other_names" placeholder="e.g. David" required>
                </div>
                <div class="form-group">
                    <label for="email">Email address</label>
                    <input type="email" class="form-control" id="email" name="email" placeholder="e.g. user@gmail.com" required>
                </div>
                <div class="form-group">
                    <label for="whatsapp_number">WhatsApp Number</label>
                    <input type="tel" class="form-control" id="whatsapp_number" name="whatsapp_number" placeholder="e.g. 08123456789" required>
                </div>
                <input type="hidden" name="action" value="checkout">
                <button type="submit" class="btn btn-primary">
                    <i class="fas fa-lock"></i> Continue with Central Wallet
                </button>
            </form>
        <?php endif; ?>
            <div class="back-to-shop">
                <a href="exam-summary.php">← Back to Shop</a>
            </div>
    </div>

    <!-- Mobile Bottom Navigation -->
    <div class="mobile-bottom-nav">
        <a href="#" data-popup-icon="fas fa-question-circle" data-popup-title="Help" data-popup-message="Click on the cart icon to view the summary files you added to the cart">
            <i class="fas fa-question-circle"></i>
            Help
        </a>
        <a href="#" data-popup-icon="fas fa-bell" data-popup-title="Notifications" data-popup-message="You have 5 new notifications">
            <i class="fas fa-bell"></i>
            Notifications
            <span class="notification-count">5</span>
        </a>
        <a href="exam-summary.php">
            <i class="fas fa-home"></i>
            Home
        </a>
        <a href="#" data-popup-icon="fas fa-info-circle" data-popup-title="Instructions" data-popup-message="Click on Add to cart to start purchasing your summary files">
            <i class="fas fa-info-circle"></i>
            Instructions
        </a>
        <a href="#" data-popup-icon="fas fa-headset" data-popup-title="Support" data-popup-message="Please reach out to us via our <a href='https://wa.me/2349166272869?text=I%20need%20assistance%20with%20the%20Exam%20Summaries%20on%20your%20website.' target='_blank'>WhatsApp link</a> for technical support.">
            <i class="fas fa-headset"></i>
            Support
        </a>
    </div>

    <div id="customPopup" class="custom-popup">
        <div class="popup-content">
            <i id="popupIcon" class="popup-icon fas fa-info-circle"></i>
            <h2 id="popupTitle"></h2>
            <p id="popupMessage"></p>
            <button class="close-button" onclick="closePopup()">Close</button>
        </div>
    </div>

    <script>
        function showPopup(iconClass, title, message) {
            document.getElementById('popupIcon').className = 'popup-icon ' + iconClass;
            document.getElementById('popupTitle').innerText = title;
            document.getElementById('popupMessage').innerHTML = "<ul>" + message + "</ul>"; // Make it a bullet point
            document.getElementById('customPopup').classList.add('show');
        }

        function closePopup() {
            document.getElementById('customPopup').classList.remove('show');
        }

        jQuery(document).ready(function() {
            jQuery('.mobile-bottom-nav a:not([href="exam-summary.php"])').click(function(e) {
                e.preventDefault();
                if (jQuery(this).data('popup-title') == "Notifications") {
                    let all_notifications = [
                        "Sign into your Course Summary account to pay from your central wallet. Your purchases will be available in the app and wallet page.",
                        "Exam summaries are primarily used for CBT exams, and they consist of keywords extracted from course materials, resembling PQs (Past Questions).",
                        "Course summaries outlines the entire course content extracting the main point(s) from your course materials. Majorly for POP students.",
                        "Solved Past Questions (SPQs) are previously answered exam questions mainly for POP students.",
                        "Exam Question Bank (EQB) is a compilation of diverse exam questions. Mainly for those taking e-Exam."
                    ];
                    showPopup(jQuery(this).data('popup-icon'), jQuery(this).data('popup-title'), all_notifications.join("<br/><hr style='border-top:1px solid var(--border); margin:10px 0;'/>"));
                } else {
                    var icon = jQuery(this).data('popup-icon');
                    var title = jQuery(this).data('popup-title');
                    var message = jQuery(this).data('popup-message');
                    showPopup(icon, title, message);
                }
            });
        });
    </script>
    <!-- Add Bootstrap JS and jQuery if needed -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.5.3/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <script src="tracking.js"></script>
</body>
</html>
<?php mysqli_close($con); ?>