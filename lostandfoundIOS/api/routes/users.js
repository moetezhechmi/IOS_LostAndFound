const express = require('express');
const router = express.Router();
const User = require('../models/user');

var jwt = require('jsonwebtoken');
var multer = require('multer');
var fs = require('fs');
var path = require('path');

var storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/images/users/')
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname)) //Appending extension
    }
});

const upload = multer({storage: storage});
var pathFolder = 'uploads/images/users/';

// signup
router.post('/signUp', function (req, res) {
    try {
        User.findOne({'email': req.body.email}, function (err, user) {
            if (err) {
                res.json({
                    status: 0,
                    message: ('Error while saving') + err
                });
            }
            if (user) {
                res.json({
                    status: 0,
                    message: ('Email already used')
                });
            } else {

                    var newUser = new User({
                        firstName: req.body.firstName,
                        lastName: req.body.lastName,
                        email: req.body.email,
                        password: req.body.password,
                       // gender: req.body.gender,
                        age: req.body.age,
                        photo: "avatar.png",
                        createdAt: Date.now(),
                    });
                    //save the user
                    newUser.save(function (err, savedUser) {
                        if (err) {
                            res.json({
                                status: 0,
                                message: err
                            });
                        } else {
                            var token = jwt.sign(savedUser.getUser(), 'MySecret', {expiresIn: 3600});
                            res.json({
                                status: 1,
                                message: 'signUp successfully',
                                data: {
                                    user: savedUser.getUser(),
                                    token: token
                                }
                            })

                        }
                    });
            }
        });
    } catch (err) {
        console.log(err);
        res.json({
            status: 0,
            message: '500 Internal Server Error',
            data: {}
        })

    }
});

//signin  user
router.post('/signIn', function (req, res) {
    try {
        User.findOne({email: req.body.email}, function (err, user) {
            if (err) {
                res.json({
                    status: 0,
                    message: ('erreur auth SignIn') + err
                });
            }

            if (!user) {
                res.json({
                    status: 0,
                    message: 'Authentication failed. User not found.'
                });
            } else {
                // check if password matches
                user.comparePassword(req.body.password, function (err, isMatch) {
                    if (isMatch && !err) {
                        // if user is found and password is right create a token
                        var token = jwt.sign(user.getUser(), 'MySecret', {expiresIn: 3600});
                        res.json({
                            status: 1,
                            message: 'Login successfully ',
                            data: {
                                user: user.getUser(),
                                token: token
                            }
                        });
                    } else {
                        res.json({
                            status: 0,
                            message: 'Authentication failed. Wrong password.'
                        });
                    }
                });
            }
        });
    } catch (err) {
        console.log(err);
        res.json({
            status: 0,
            message: '500 Internal Server Error',
            data: {}
        })

    }
});


// update user
router.post('/updateUser', upload.single('file'), function (req, res) {
    try {
        if (req.file) {
            User.findOne({_id: req.body.userId}, function (err, user) {
                if (user.photo !== undefined) {
                    var fullPath = pathFolder + user.photo;
                    fs.stat(fullPath, function (err, stats) {
                        if (err) {
                            return console.error(err);
                        }
                        // delete old image profile from floder
                        if (user.photo != "avatar.png"){
                            fs.unlink((fullPath), function (err) {
                                if (err) return console.log(err);
                                console.log('file deleted successfully');
                            });
                        }

                    });
                }
            });
        }
        User.findOne({_id: req.body.userId}, function (err, user) {
            if (err) {
                res.json({
                    status: 0,
                    message: ('Error update user') + err
                });
            } else {
                if (!user) {
                    res.json({
                        status: 0,
                        message: ('user does not exist')

                    });
                } else {
                    try {
                        if (req.body.email) {
                            user.email = req.body.email;
                        }
                        if (req.body.firstName) {
                            user.firstName = req.body.firstName;
                        }
                        if (req.body.lastName) {
                            user.lastName = req.body.lastName;
                        }
                        if (req.body.gender) {
                            user.gender = req.body.gender;
                        }
                        if (req.body.age) {
                            user.age = req.body.age;
                        }
                        if (req.file) {
                            user.photo = req.file.filename;
                        }
                        if (req.body.oldPassword && req.body.newPassword) {
                            // check if password matches
                            user.comparePassword(req.body.oldPassword, function (err, isMatch, next) {
                                if (isMatch && !err) {
                                    user.password = req.body.newPassword;
                                    user.save(function (err, savedUser) {
                                        if (err) {
                                            res.json({
                                                status: 0,
                                                message: ('error Update user ') + err
                                            });
                                        } else {
                                            var token = jwt.sign(savedUser.getUser(), 'MySecret', {expiresIn: 36000});
                                            res.json({
                                                status: 1,
                                                message: 'profil modifié avec succés',
                                                data: {
                                                    user: savedUser.getUser(),
                                                    token: token
                                                }
                                            })
                                        }
                                    });
                                    
                                } else {
                                    res.json({
                                        status: 0,
                                        message: 'update user failed. Wrong password.'
                                    });
                                }
                            });
                        } else {
                        user.save(function (err, savedUser) {
                            if (err) {
                                res.json({
                                    status: 0,
                                    message: ('error Update user ') + err
                                });
                            } else {
                                var token = jwt.sign(savedUser.getUser(), 'MySecret', {expiresIn: 3600});
                                res.json({
                                    status: 1,
                                    message: 'profil modifié avec succés',
                                    data: {
                                        user: savedUser.getUser(),
                                        token: token
                                    }
                                })
                            }
                        });
                    }
                } catch (err) {
                    console.log(err);
                    res.json({
                        status: 0,
                        message: '500 Internal Server Error',
                        data: {}
                    })

                }
                }

            }

        });
    } catch (err) {
        console.log(err);
        res.json({
            status: 0,
            message: '500 Internal Server Error',
            data: {}
        })

    }
});


// get User By Id
router.post('/getUserById', function (req, res) {
    try {
        User.findOne({_id: req.body.userId}, function (err, user) {
            if (err) {
                return res.json({
                    status: 0,
                    message: ('error get Profile ' + err)
                });
            }
            if (!user) {
                return res.json({
                    status: 0,
                    message: ('user does not exist')
                });
            }
             else {
                    res.json({
                        status: 1,
                        message: 'get Profile successfully',
                        data: {
                            user: user.getUser(),
                        }
                    });
                }
        });
    } catch (err) {
        console.log(err);
        res.json({
            status: 0,
            message: '500 Internal Server Error',
            data: {}
        })

    }
});

module.exports = router;