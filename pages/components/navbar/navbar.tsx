/** @format */

import React from "react"
import {Navbar, Button, Link, Text} from "@nextui-org/react"

interface AllInOneProps {}

const NavbarComponent: any = ({}) => {
  return (
    <Navbar isBordered variant='floating'>
      <Navbar.Brand>
        <Text color='inherit'>Gashapon</Text>
      </Navbar.Brand>

      <Navbar.Content>
        <Navbar.Item>
          <Button flat>Connect Wallet</Button>
        </Navbar.Item>
      </Navbar.Content>
    </Navbar>
  )
}

export default NavbarComponent
