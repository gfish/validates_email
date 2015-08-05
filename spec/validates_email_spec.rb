# encoding: utf-8
require 'spec_helper'

describe EmailValidator do
  context 'w/o mx fallback' do
    it 'allows valid emails' do
      [
        'valid@example.com',
        'Valid@test.example.com',
        'valid+valid123@test.example.com',
        'valid_valid123@test.example.com',
        'valid-valid+123@test.example.co.uk',
        'valid-valid+1.23@test.example.com.au',
        'valid@example.co.uk',
        'v@example.com',
        'valid@example.ca',
        'valid_@example.com',
        'valid_2@example.com',
        'valid__me@example.com',
        'valid123.456@example.org',
        'valid123.456@example.travel',
        'valid123.456@example.museum',
        'valid@example.mobi',
        'valid@example.info',
        'valid-@example.com',
        # from RFC 3696, page 6
        'customer/department=shipping@example.com',
        '$A12345@example.com',
        '!def!xyz%abc@example.com',
        '_somename@example.com',
        # apostrophes
        "test'test@example.com",
        # .sch.uk
        'valid@example.w-dash.sch.uk'
      ].each do |email|
        person = Person.new(primary_email: email)
        expect(person).to be_valid(email)
      end
    end

    # From http://www.rfc-editor.org/errata_search.php?rfc=3696
    it 'allows quoted characters' do
      [
        '"Abc\@def"@example.com',
        '"Fred\ Bloggs"@example.com',
        '"Joe.\\Blow"@example.com'
      ].each do |email|
        person = Person.new(primary_email: email)
        expect(person).to be_valid(email)
      end
    end

    it "doesn't allow invalid emails" do
      [
        'invalid@example-com',
        # period can not start local part
        '.invalid@example.com',
        # period can not end local part
        'invalid.@example.com',
        # period can not appear twice consecutively in local part
        'invali..d@example.com',
        # should not allow underscores in domain names
        'invalid@ex_mple.com',
        'invalid@example.com.',
        'invalid@example.com_',
        'invalid@example.com-',
        'invalid-example.com',
        'invalid@example.b#r.com',
        'invalid@example.c',
        'invali d@example.com',
        'invalidexample.com',
        'invalid@example.',
        'чебурашка@kremlin.ru',
        'invalid++email@example.com'
      ].each do |email|
        person = Person.new(primary_email: email)
        expect(person).to_not be_valid(email)
      end
    end

    it "doesn't raise exception for emails with UTF-8 characters" do
      person = Person.new(primary_email: 'чебурашка@kremlin.ru')
      expect do
        person.valid?
      end.not_to raise_error
    end

    # From http://tools.ietf.org/html/rfc3696, page 5
    # Corrected in http://www.rfc-editor.org/errata_search.php?rfc=3696
    it "doesn't allow escaped characters without quotes" do
      [
        'Fred\ Bloggs_@example.com',
        'Abc\@def+@example.com',
        'Joe.\\Blow@example.com'
      ].each do |email|
        person = Person.new(primary_email: email)
        expect(person).to_not be_valid(email)
      end
    end

    it "doesn't allow long emails" do
      [
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@example.com',
        'test@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com'
      ].each do |email|
        person = Person.new(primary_email: email)
        expect(person).to_not be_valid(email)
      end
    end
  end

  context 'w/ MX fallback' do
    it 'allows valid email' do
      email = 'test@gmail.com'
      person = PersonMX.new(primary_email: email)
      expect(person).to be_valid(email)
    end

    it "doesn't allow invalid email" do
      email = 'test@example.com'
      person = PersonMX.new(primary_email: email)
      expect(person).to_not be_valid(email)
    end

    it "doesn't validate mx with invalid email" do
      email = 'testexample.com'
      expect do
        person = PersonMX.new(primary_email: email)
        expect(person).to_not be_valid(email)
      end.to_not raise_error
    end
  end

  context 'w/ A record MX fallback' do
    it 'allows valid email' do
      email = 'test@gmail.com'
      person = PersonMXA.new(primary_email: email)
      expect(person).to be_valid(email)
    end

    it 'allows valid email with fallback to A' do
      email = 'test@example.com'
      person = PersonMXA.new(primary_email: email)
      expect(person).to be_valid(email)
    end
  end

  context 'w/ custom error messages' do
    it 'allows custom error message' do
      email = 'example.com'
      person = PersonMessage.new(primary_email: email)
      expect(person).to_not be_valid(email)
      expect(person.errors[:primary_email]).to eql(['fails with custom message'])
    end

    it 'allows custom error message for mx fallback' do
      email = 'test@example.com'
      person = PersonMXMessage.new(primary_email: email)
      expect(person).to_not be_valid(email)
      expect(person.errors[:primary_email]).to eql(['fails with custom mx message'])
    end
  end

  context 'with proc-based MX validation' do
    it 'allows valid email' do
      email = 'test@gmail.com'
      person = PersonProcMX.new(primary_email: email)
      expect(person).to be_valid(email)
    end

    it 'allows invalid email if proc evaluates to false' do
      email = 'test@example.com'
      person = PersonProcMX.new(primary_email: email)
      person.with_mx_validation = false
      expect(person).to be_valid(email)
    end

    it 'does not allow invalid email if proc evaluates to true' do
      email = 'test@example.com'
      person = PersonProcMX.new(primary_email: email)
      person.with_mx_validation = true
      expect(person).to_not be_valid(email)
    end
  end

  context 'with proc-based MX validation with fallback to A' do
    it 'allows valid email' do
      email = 'test@gmail.com'
      person = PersonProcMXA.new(primary_email: email)
      expect(person).to be_valid(email)
    end

    it 'allows valid email with fallback to A' do
      email = 'test@example.com'
      person = PersonMXA.new(primary_email: email)
      expect(person).to be_valid(email)
    end

    it 'allows invalid email if proc evaluates to false' do
      email = 'test@exampledoesnotexist.com'
      person = PersonProcMXA.new(primary_email: email)
      person.with_mx_validation = false
      expect(person).to be_valid(email)
    end

    it 'does not allow invalid email if proc evaluates to true' do
      email = 'test@exampledoesnotexist.com'
      person = PersonProcMX.new(primary_email: email)
      person.with_mx_validation = true
      expect(person).to_not be_valid(email)
    end
  end
end
