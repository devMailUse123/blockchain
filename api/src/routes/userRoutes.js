const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

/**
 * @route   POST /api/users
 * @desc    Créer un nouvel utilisateur
 * @access  Public
 */
router.post('/', userController.createUser);

/**
 * @route   GET /api/users/:id
 * @desc    Récupérer un utilisateur par son ID
 * @access  Public
 */
router.get('/:id', userController.getUser);

/**
 * @route   GET /api/users
 * @desc    Récupérer tous les utilisateurs
 * @access  Public
 */
router.get('/', userController.getAllUsers);

module.exports = router;
