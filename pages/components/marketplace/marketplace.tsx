/** @format */

import axios from "axios"
import {Button, Card, Grid, Row, Text} from "@nextui-org/react"
import Gashapon_V1 from "../../../Gashapon_V1.json"
import React, {useState} from "react"
import OneNftComponent from "../modals/oneNft"
// import OneNftComponent from "../modals/oneNft"

const MarketplaceComponent: any = ({}) => {
  const [data, updateData] = useState([] as any[])
  const [dataFetched, updateFetched] = useState(false)
  const [addr, updateAddress] = useState("0x")

  async function getAllNFTs() {
    const ethers = require("ethers")
    //After adding your Hardhat network to your metamask, this code will get providers and signers
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    const signer = provider.getSigner()

    const addr = await signer.getAddress()
    updateAddress(addr)

    //Pull the deployed contract instance
    let contract = new ethers.Contract(Gashapon_V1.address, Gashapon_V1.abi, signer)
    //create an NFT Token
    let transaction = await contract.getAllNFTs()

    //Fetch all the details of every NFT from the contract and display
    const items: any[] = await Promise.all(
      transaction.map(async (i: any) => {
        const tokenURI = await contract.tokenURI(i.tokenId)
        let meta = await axios.get(tokenURI)
        const data: {name: string; image: string; description: string} = meta.data

        let price = ethers.utils.formatUnits(i.price.toString(), "ether")
        let item = {
          price,
          tokenId: i.tokenId.toNumber(),
          seller: i.seller,
          owner: i.owner,
          image: data.image,
          name: data.name,
          description: data.description,
        }
        return item
      })
    )
    updateFetched(true)
    updateData(items)
  }

  if (!dataFetched) getAllNFTs()

  const [visible, setVisible] = React.useState({} as any)
  const handler = (index: any) => {
    setVisible({
      show: {
        [index]: true,
      },
    })
  }

  const [modalData, setModalData] = useState<any>(null)

  const showDetail = (data: any, index: number, show: boolean) => {
    setModalData({
      ...data,
      index: index,
      show: show,
    })
  }

  return (
    <Grid.Container gap={2} justify='flex-start'>
      {data.map((item, index) => (
        <Grid xs={6} sm={3} key={index}>
          <Card isPressable>
            <Card.Body css={{p: 0}}>
              <Card.Image
                src={item.image}
                objectFit='cover'
                width='100%'
                height={140}
                alt={item.name}
                onClick={() => {
                  showDetail(item, index, true)
                }}
              />
            </Card.Body>
            <Card.Footer css={{justifyItems: "flex-start"}}>
              <Row wrap='wrap' justify='space-between' align='center'>
                <Text b>{item.name}</Text>

                {addr === item.seller ? (
                  <Button color='success' auto>
                    Yours
                  </Button>
                ) : (
                  ""
                )}

                <Text
                  css={{color: "$accents7", fontWeight: "$semibold", fontSize: "$sm"}}
                >
                  {item.price}
                </Text>
              </Row>
            </Card.Footer>
          </Card>
        </Grid>
      ))}

      {modalData && modalData.show && (
        <OneNftComponent
          data={{
            name: modalData?.name,
            image: modalData?.image,
            description: modalData?.description,
            price: modalData?.price,
          }}
          show={modalData?.show}
          showDetail={showDetail}
        />
      )}
    </Grid.Container>
  )
}

export default MarketplaceComponent
