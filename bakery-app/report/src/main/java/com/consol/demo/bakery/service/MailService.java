/*
 * Copyright 2006-2015 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.consol.demo.bakery.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;

import javax.mail.*;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.util.Date;
import java.util.Properties;

/**
 * @author Christoph Deppisch
 * @since 2.4
 */
public class MailService {

    /**
     * Logger
     */
    private static Logger log = LoggerFactory.getLogger(MailService.class);

    @Value("${MAIL_PORT_2222_TCP_ADDR:localhost}")
    private String mailServerHost;

    @Value("${MAIL_PORT_2222_TCP_PORT:2222}")
    private String mailServerPort;

    private String from = "cookie-report@example.com";
    private String username = "cookie-report@example.com";
    private String password = "secretpw";

    /**
     * Send mail via SMTP connection.
     *
     * @param to
     * @param subject
     * @param body
     */
    public void sendMail(String to, String subject, String body) {
        Properties props = new Properties();
        props.put("mail.smtp.host", mailServerHost);
        props.put("mail.smtp.port", mailServerPort);
        props.put("mail.smtp.auth", true);

        Authenticator authenticator = new Authenticator() {
            private PasswordAuthentication pa = new PasswordAuthentication(username, password);

            @Override
            public PasswordAuthentication getPasswordAuthentication() {
                return pa;
            }
        };

        Session session = Session.getInstance(props, authenticator);
        session.setDebug(true);
        MimeMessage message = new MimeMessage(session);
        try {
            message.setFrom(new InternetAddress(from));
            InternetAddress[] address = {new InternetAddress(to)};
            message.setRecipients(Message.RecipientType.TO, address);
            message.setSubject(subject);
            message.setSentDate(new Date());
            message.setText(body);
            Transport.send(message);
        } catch (MessagingException e) {
            log.error("Failed to send mail!", e);
        }
    }
}
