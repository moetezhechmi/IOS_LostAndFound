const express = require('express');
require('dotenv').config();
const router = express.Router();
const User = require('../models/user');
var nodemailer = require('nodemailer');

//const mailgun = require("mailgun-js");
const DOMAIN = 'sandbox7d776a63b8444fdaa7a16fd19538f7de';
//const mg = mailgun({apiKey: process.env.MAILGUN_APIKEY, domain: DOMAIN});

var jwt = require('jsonwebtoken');
var multer = require('multer');
var fs = require('fs');
var path = require('path');
//const { MAILGUN_APIKEY } = require('../config');

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
    console.log(req.body);
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

                  /* var token = jwt.sign({'firstName': req.body.email,'lastName': req.body.lastName,'email':req.body.email,'password':req.body.password,'age':req.body.age,'photo':req.body.photo,'createdAt':req.body.createdAt}, 'MySecret', {expiresIn: 3600});

               

                    var transporter = nodemailer.createTransport({
                    service: 'gmail',
                    auth: {
                        user: 'landfound514@gmail.com',
                        pass: 'lostfoundesprit'
                    }
                    });

                    var mailOptions = {
                    from: 'landfound514@gmail.com',
                    to: req.body.email,
                    subject: 'Activation Lien ',
                    html:`
                    <h2> s'il vous plaît cliquez sur ce lien pour activer votre compte</h2
                    <p>${process.env.CLIENT_URL}/Authentication/activate/${token}</p>
                    `

                    };

                    transporter.sendMail(mailOptions, function(error, info){
                    if (error) {
                        console.log(error);
                    } else {
                        console.log('Email sent: ' + info.response);
                    }
                    });
                    */




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

//Activate Account
router.post('/email-activate'), function (req, res) {
    const {token} = req.body;
    if(token){
        jwt.verify(token,'MySecret',function(err,decodedToken){
          if(err){
              return res.status(400).json({error: "Incorrect or Expired link"})
          } 
          const {firstName, lastName, password, email, photo, age, createdAt}= decodedToken;

        })
    }else{
        return res.json({error: "Something went wrong!!!"})
    }
}


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
                                                message: 'Update user successfully!!!!',
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
                                    message: 'Profil modifié avec succées',
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