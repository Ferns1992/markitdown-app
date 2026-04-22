from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user, login_required, current_user
from app import db
from app.models import User

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('main.index'))

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        user = User.query.filter_by(username=username).first()

        if user and user.check_password(password):
            if not user.is_approved:
                flash('Account pending approval', 'warning')
                return render_template('login.html')

            login_user(user)
            return redirect(url_for('main.index'))

        flash('Invalid credentials', 'danger')

    return render_template('login.html')

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('main.index'))

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        if User.query.filter_by(username=username).first():
            flash('Username already exists', 'danger')
            return render_template('register.html')

        user = User(username=username)
        user.set_password(password)
        user.is_approved = False

        db.session.add(user)
        db.session.commit()
        flash('Registration submitted. Await admin approval.', 'success')
        return redirect(url_for('auth.login'))

    return render_template('register.html')

@auth_bp.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('auth.login'))

@auth_bp.route('/admin')
@login_required
def admin():
    if not current_user.is_admin:
        flash('Admin access required', 'danger')
        return redirect(url_for('main.index'))

    users = User.query.all()
    pending = User.query.filter_by(is_approved=False, is_admin=False).all()
    return render_template('admin.html', users=users, pending=pending)

@auth_bp.route('/admin/approve/<int:user_id>')
@login_required
def approve_user(user_id):
    if not current_user.is_admin:
        flash('Admin access required', 'danger')
        return redirect(url_for('main.index'))

    user = User.query.get_or_404(user_id)
    user.is_approved = True
    db.session.commit()
    flash(f'User {user.username} approved', 'success')
    return redirect(url_for('auth.admin'))

@auth_bp.route('/admin/reject/<int:user_id>')
@login_required
def reject_user(user_id):
    if not current_user.is_admin:
        flash('Admin access required', 'danger')
        return redirect(url_for('main.index'))

    user = User.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    flash('User rejected and removed', 'success')
    return redirect(url_for('auth.admin'))