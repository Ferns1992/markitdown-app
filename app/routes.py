import os
from markitdown import MarkItDown
from flask import Blueprint, request, jsonify, current_app
from flask_login import login_required, current_user
from werkzeug.utils import secure_filename
from app import db
from app.models import Conversion

main_bp = Blueprint('main', __name__)

def allowed_file(filename):
    ext = filename.rsplit('.', 1)[-1].lower() if '.' in filename else ''
    allowed = {'pdf', 'ppt', 'pptx', 'doc', 'docx', 'xls', 'xlsx',
              'jpg', 'jpeg', 'png', 'gif', 'wav', 'mp3',
              'csv', 'json', 'xml', 'html', 'epub', 'zip',
              'txt', 'md', 'msg', 'rtf', 'url'}
    return ext in allowed

def login_required_json(f):
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify({'error': 'Login required', 'redirect': '/login'}), 401
        return f(*args, **kwargs)
    return decorated_function

@main_bp.route('/')
def index():
    from flask import render_template
    return render_template('index.html')

@main_bp.route('/upload', methods=['POST'])
@login_required_json
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    filename = secure_filename(file.filename)
    ext = filename.rsplit('.', 1)[-1].lower() if '.' in filename else ''

    if not allowed_file(file.filename):
        return jsonify({'error': 'File type not allowed: ' + ext}), 400

    upload_folder = current_app.config['UPLOAD_FOLDER']
    filepath = os.path.join(upload_folder, f"{current_user.id}_{filename}")

    # Read file content first to check
    file_content = file.read()
    current_app.logger.info(f'File size: {len(file_content)}, ext: {ext}')

    # Save temp file for debugging
    debug_path = os.path.join(upload_folder, 'debug_' + ext)
    open(debug_path, 'wb').write(file_content)
    current_app.logger.info(f'Debug file: {debug_path}')

    # Save to actual path
    open(filepath, 'wb').write(file_content)

    conversion = Conversion(
        user_id=current_user.id,
        original_filename=filename,
        status='processing'
    )
    db.session.add(conversion)
    db.session.commit()

    try:
        md = MarkItDown(enable_plugins=False)
        result = md.convert(filepath)
        conversion.markdown_output = result.text_content
        conversion.status = 'completed'
        db.session.commit()
        return jsonify({
            'success': True,
            'conversion_id': conversion.id,
            'markdown': result.text_content
        })
    except Exception as e:
        conversion.status = 'failed'
        db.session.commit()
        return jsonify({'error': str(e)}), 500
    finally:
        if os.path.exists(filepath):
            os.remove(filepath)

@main_bp.route('/history')
@login_required
def history():
    from flask import render_template
    conversions = Conversion.query.filter_by(user_id=current_user.id).order_by(
        Conversion.created_at.desc()).all()
    return render_template('history.html', conversions=conversions)